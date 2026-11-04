"""Local BiRefNet mask prototype. This is not an automatic asset acceptance gate.

Requires isolated onnxruntime; model is the checksum-verified rembg release.
Run --samples to write only review images. No game assets are changed.
"""
from pathlib import Path
import argparse
import ctypes
import hashlib
import json
import os
import tempfile
import time
import warnings

import cv2
import numpy as np
import onnxruntime as ort
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

BASE = Path(__file__).resolve().parent
DEFAULT_MODEL = BASE.parents[3] / 'work/action36-models/birefnet-general-lite.onnx'


class SemanticMatte:
    def __init__(self, model_path=DEFAULT_MODEL, threads=4, provider='cpu', device_id=0, profile_prefix=None, dml_fusion=False, model_family='birefnet'):
        if model_family not in ('birefnet', 'u2net', 'isnet'):
            raise ValueError(f'Unsupported model family: {model_family}')
        self.model_family = model_family
        self.input_size = 320 if model_family == 'u2net' else 1024
        options = ort.SessionOptions()
        options.intra_op_num_threads = threads
        options.inter_op_num_threads = 1
        providers = ['CPUExecutionProvider']
        self._dll_handles = []
        if provider == 'cuda':
            if 'CUDAExecutionProvider' not in ort.get_available_providers():
                raise RuntimeError('CUDA unavailable: put isolated onnxruntime-gpu directory first on PYTHONPATH')
            dependency_root = Path(ort.__file__).resolve().parents[1]
            if os.name == 'nt':
                directories = list((dependency_root / 'nvidia').glob('*/bin'))
                # cuDNN loads optional engines via legacy LoadLibrary as well as
                # Python's DLL-directory search; this PATH change is process-only.
                os.environ['PATH'] = os.pathsep.join(map(str, directories)) + os.pathsep + os.environ.get('PATH', '')
                for directory in directories:
                    self._dll_handles.append(os.add_dll_directory(str(directory)))
            if hasattr(ort, 'preload_dlls'):
                ort.preload_dlls(cuda=True, cudnn=True, msvc=True, directory='')
            if os.name == 'nt':
                for library in (dependency_root / 'nvidia/cudnn/bin').glob('cudnn*.dll'):
                    self._dll_handles.append(ctypes.WinDLL(str(library)))
            providers = [('CUDAExecutionProvider', {
                'device_id': device_id, 'gpu_mem_limit': 5 * 1024**3,
                'cudnn_conv_algo_search': 'HEURISTIC',
                'cudnn_conv_use_max_workspace': '0', 'use_tf32': '0',
            }), 'CPUExecutionProvider']
        if provider == 'dml':
            if 'DmlExecutionProvider' not in ort.get_available_providers():
                raise RuntimeError('DML unavailable: use isolated onnxruntime-directml PYTHONPATH first')
            options.enable_mem_pattern = False
            options.execution_mode = ort.ExecutionMode.ORT_SEQUENTIAL
            options.add_session_config_entry('ep.dml.disable_graph_fusion', '0' if dml_fusion else '1')
            providers = [('DmlExecutionProvider', {'device_id': device_id}), 'CPUExecutionProvider']
        if profile_prefix:
            options.enable_profiling = True
            options.profile_file_prefix = str(profile_prefix)
        self.session = ort.InferenceSession(str(model_path), sess_options=options,
                                            providers=providers)
        # ORT may otherwise retry run() on CPU without throwing. The helper owns
        # explicit fallback so callers never mistake a CPU result for GPU proof.
        self.session.disable_fallback()
        self.input_name = self.session.get_inputs()[0].name
        self.input_shape = self.session.get_inputs()[0].shape
        self.model_tag = hashlib.sha256(Path(model_path).read_bytes()).hexdigest() + ':rembg-normalize-max:1024:lanczos:sigmoid-v1'
        if model_family != 'birefnet':
            self.model_tag = hashlib.sha256(Path(model_path).read_bytes()).hexdigest() + f':rembg-{model_family}-normalize-max:{self.input_size}:lanczos:raw-output-v1'
        actual = self.session.get_providers()
        wanted = {'cuda': 'CUDAExecutionProvider', 'dml': 'DmlExecutionProvider'}.get(provider)
        self.provider = provider if not wanted or wanted in actual else 'cpu'
        if wanted and self.provider == 'cpu':
            warnings.warn(f'{wanted} did not initialize; using unchanged model on CPU')
        self.model_path = model_path
        self.threads = threads

    def predict(self, rgb, cache_dir=None):
        """Return unthresholded HxW foreground probability; inspect before use."""
        cache_path = None
        if cache_dir is not None:
            key = hashlib.sha256(self.model_tag.encode() + str(rgb.shape).encode() + rgb.tobytes()).hexdigest()
            cache_path = Path(cache_dir) / (key + '.npy')
            if cache_path.exists():
                cached = np.load(cache_path)
                if cached.shape == rgb.shape[:2] and np.isfinite(cached).all():
                    return cached
                raise RuntimeError(f'Invalid cached mask: {cache_path}')
        im = Image.fromarray(rgb).resize((self.input_size, self.input_size), Image.Resampling.LANCZOS)
        x = np.asarray(im, dtype=np.float32)
        x /= max(float(x.max()), 1e-6)
        if self.model_family == 'isnet':
            x -= .5
        else:
            x = (x - np.array([.485, .456, .406], np.float32)) / np.array([.229, .224, .225], np.float32)
        feed = x.transpose(2, 0, 1)[None]
        try:
            output = self.session.run(None, {self.input_name: feed})[0]
            pred = output[0, 0]
            if self.model_family == 'birefnet':
                pred = 1 / (1 + np.exp(-np.clip(pred, -60, 60)))
            if not np.isfinite(pred).all() or float(pred.max() - pred.min()) < 1e-5:
                raise RuntimeError('Invalid constant/non-finite semantic mask; refusing blank output')
        except Exception as error:
            if self.provider not in ('dml', 'cuda'):
                raise
            warnings.warn(f'{self.provider} failed ({error!r}); switching this session to CPU at unchanged {self.input_size} resolution')
            fallback = SemanticMatte(self.model_path, self.threads, provider='cpu', model_family=self.model_family)
            self.session = fallback.session
            self.input_name = fallback.input_name
            self.provider = 'cpu'
            return self.predict(rgb, cache_dir)
        pred = (pred - pred.min()) / (pred.max() - pred.min())
        result = cv2.resize(pred, (rgb.shape[1], rgb.shape[0]), interpolation=cv2.INTER_LINEAR).clip(0, 1)
        if cache_path is not None:
            cache_path.parent.mkdir(parents=True, exist_ok=True)
            with tempfile.NamedTemporaryFile(dir=cache_path.parent, suffix='.npy', delete=False) as handle:
                np.save(handle, result)
                temp_path = handle.name
            os.replace(temp_path, cache_path)
        return result


def background_color(rgb):
    h, w = rgb.shape[:2]
    return np.median(np.concatenate([rgb[:h//6, :w//6].reshape(-1, 3),
                                     rgb[:h//6, -w//6:].reshape(-1, 3)]), axis=0).astype(np.float32)


def body_rgba(rgb, probability, reject_rects=(), preserve_regions=()):
    """Conservative semantic body, plus source-colour edge unmixing.

    reject_rects are manually reviewed source-pixel x0,y0,x1,y1 regions.
    They must not overlap the fork or body. No global gold/cyan pixel stealing.
    The network can retain props/FX and cannot recover occluded body pixels.
    """
    alpha = probability.copy()
    for x0, y0, x1, y1 in reject_rects:
        alpha[y0:y1, x0:x1] = 0
    # Remove distant disconnected objects, but retain thin neighbouring gear.
    labels, n = ndi.label(alpha > .5)
    if n:
        sizes = np.bincount(labels.ravel()); sizes[0] = 0
        main = labels == sizes.argmax()
        for x0,y0,x1,y1 in preserve_regions:
            # A bright spin arc can disconnect otherwise intact dark legs.
            # Retain semantic components with real dark costume pixels in a
            # reviewed leg region; never fill the intervening bright effect.
            seed=np.zeros(labels.shape,dtype=bool)
            seed[max(0,y0):min(y1,labels.shape[0]),max(0,x0):min(x1,labels.shape[1])]=True
            seed &= (rgb.mean(2)<140)&(alpha>.5)
            candidates,counts=np.unique(labels[seed],return_counts=True)
            keep=candidates[(candidates!=0)&(counts>=5)]
            main |= np.isin(labels,keep)
        near = ndi.binary_dilation(main, iterations=5)
        alpha *= near
    bg = background_color(rgb)
    a = rgb.astype(np.float32)
    # Unmix only soft semantic edges, preserving opaque source costume shading.
    soft = (alpha > .01) & (alpha < .99)
    clean = bg + (a - bg) / np.maximum(alpha[..., None], .08)
    a[soft] = clean[soft].clip(0, 255)
    alpha[alpha < .01] = 0
    a[alpha == 0] = 0
    return Image.fromarray(np.dstack([a, alpha * 255]).astype(np.uint8))


def frame(path, seconds, width=768):
    cap = cv2.VideoCapture(str(path))
    cap.set(cv2.CAP_PROP_POS_MSEC, seconds * 1000)
    ok, bgr = cap.read(); cap.release()
    if not ok:
        raise RuntimeError(f'Cannot read {path} at {seconds}')
    return cv2.cvtColor(cv2.resize(bgr, (width, round(bgr.shape[0]*width/bgr.shape[1]))), cv2.COLOR_BGR2RGB)


def samples(model_path):
    engine = SemanticMatte(model_path)
    source_file = BASE.parents[3] / 'outputs/拾潮者_14集参考_左右动作全集/selected_sources.json'
    source = {a['action']: a['source'] for a in json.loads(source_file.read_text(encoding='utf-8'))}
    review = BASE / 'review'
    results = []
    for key, seconds in [('dash', 1.4), ('run', 1.1), ('pogo', 1.75)]:
        rgb = frame(source[key], seconds)
        start = time.perf_counter(); probability = engine.predict(rgb); elapsed = time.perf_counter()-start
        Image.fromarray((probability*255).astype(np.uint8)).save(review / f'{key}-semantic-mask.png')
        cut = body_rgba(rgb, probability)
        cut.save(review / f'{key}-semantic-body.png')
        w, h = cut.size
        sheet = Image.new('RGB', (w*2, (h+24)*2), '#122c38')
        draw = ImageDraw.Draw(sheet)
        mask_view = Image.fromarray((probability*255).astype(np.uint8)).convert('RGB')
        sheet.paste(Image.fromarray(rgb), (0, 0)); sheet.paste(mask_view, (w, 0))
        for j, color in enumerate(['#122c38', '#eee8dd']):
            tile = Image.new('RGBA', cut.size, color); tile.alpha_composite(cut)
            sheet.paste(tile.convert('RGB'), (j*w, h+24))
        for text, x, y in [('source',0,h),('raw model mask',w,h),('semantic + unmix: dark',0,2*h+24),('semantic + unmix: light',w,2*h+24)]:
            draw.text((x+8,y+4),text,fill='white')
        sheet.save(review / f'{key}-semantic-review.jpg', quality=95)
        results.append({'key':key,'seconds':seconds,'source':source[key],'inference_seconds':elapsed,'status':'unreviewed'})
        print(key, elapsed, flush=True)
    (review/'semantic-sample-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--model', type=Path, default=DEFAULT_MODEL)
    parser.add_argument('--samples', action='store_true')
    args = parser.parse_args()
    if args.samples:
        samples(args.model)
