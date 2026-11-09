"""Temporary fixtures only: never read or write the production catalog/manifest."""
import copy
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from PIL import Image
import registration as reg


class RegistrationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='bob-action36-register-test-')
        self.repo = Path(self.temp.name).resolve()
        self.runtime = self.repo / 'assets/runtime/sprites/tide-picker-action36'
        self.game = self.repo / 'game/art/tide-picker-action36'
        self.source = self.repo / 'assets/source/tide-picker-action36'
        for directory in (self.runtime, self.game, self.source):
            directory.mkdir(parents=True)
        self.action = {'title': 'fixture', 'source': 'fixture.mp4', 'source_sha256': 'source-hash',
                       'frame_count': 1, 'fps': 12, 'body': self.layer('run-body.png'), 'fx': None}
        self.data = {'actions': {'run': self.action}}
        self.manifest = {'entries': [{'src': 'other', 'dest': 'other/kept.png'}]}
        self.catalog = {'revision': 7, 'assets': [{'id': 'unrelated', 'status': 'accepted'}]}
        self.write_inputs()

    def tearDown(self):
        self.temp.cleanup()

    def layer(self, name, color=(10,20,30,255)):
        Image.new('RGBA', (2,2), color).save(self.runtime / name)
        return {'texture': reg.URI + name, 'sha256': reg.sha256(self.runtime / name),
                'size': [2,2], 'pivot': [1,2], 'frames': [[0,0,2,2]]}

    def write_inputs(self):
        reg.write_json(self.runtime / 'animations.json', self.data)
        reg.write_json(self.repo / 'game/art/manifest.json', self.manifest)
        reg.write_json(self.repo / 'assets/catalog.json', self.catalog)

    def validation(self, art='passed'):
        stage = {'status': 'passed', 'reviewer': 'fixture-reviewer', 'reviewed_at': '2026-11-04T12:00:00Z',
                 'evidence': ['fixture evidence; not a production acceptance claim']}
        record = {'hashes': {'body': self.action['body']['sha256'], 'fx': self.action['fx']['sha256'] if self.action['fx'] else None},
                  **{name: copy.deepcopy(stage) for name in reg.STAGES}}
        record['art']['status'] = art
        value = {'version': 1, 'actions': {'run': record}}
        reg.write_json(self.source / 'validation.json', value)
        return value

    def entries(self):
        return reg.read_json(self.repo / 'assets/catalog.json')['assets']

    def test_missing_review_and_dry_run_never_promote_or_write(self):
        result = reg.register(self.repo, dry_run=True)
        self.assertEqual(result['actions']['run']['status'], 'candidate')
        self.assertEqual(reg.read_json(self.repo / 'assets/catalog.json'), self.catalog)
        self.assertEqual(reg.read_json(self.repo / 'game/art/manifest.json'), self.manifest)

    def test_explicit_matching_review_preserves_unrelated_and_separates_user_approval(self):
        value = self.validation()
        reg.register(self.repo)
        self.assertEqual(self.entries()[0], self.catalog['assets'][0])
        self.assertEqual(self.entries()[1]['status'], 'accepted')
        self.assertFalse(self.entries()[1]['userArtApproval'])
        self.assertEqual(reg.read_json(self.repo / 'game/art/manifest.json')['entries'][0], self.manifest['entries'][0])
        value['actions']['run']['art'].update(reviewer_kind='user', user_approved=True)
        reg.write_json(self.source / 'validation.json', value)
        reg.register(self.repo)
        self.assertTrue(self.entries()[1]['userArtApproval'])

    def test_changed_body_or_added_fx_invalidates_entire_action_review(self):
        self.validation()
        self.action['body'] = self.layer('run-body.png', (90,80,70,255))
        self.write_inputs()
        reg.register(self.repo)
        self.assertEqual(self.entries()[1]['status'], 'candidate')
        self.assertFalse(self.entries()[1]['validation']['hashMatched'])
        self.validation()
        self.action['fx'] = self.layer('run-fx.png')
        self.write_inputs()
        reg.register(self.repo)
        for entry in self.entries()[1:]:
            self.assertEqual(entry['status'], 'candidate')
            self.assertEqual(entry['validation']['stages']['runtime']['status'], 'pending')

    def test_runtime_pass_is_not_art_pass_and_incomplete_claim_is_pending(self):
        value = self.validation(art='pending')
        reg.register(self.repo)
        self.assertEqual(self.entries()[1]['status'], 'candidate')
        self.assertEqual(self.entries()[1]['integrationStatus'], 'main-level-integrated')
        value['actions']['run']['technical']['evidence'] = []
        reg.write_json(self.source / 'validation.json', value)
        reg.register(self.repo)
        self.assertEqual(self.entries()[1]['integrationStatus'], 'pending-verification')

    def test_sprite_sheet_is_not_registered_as_video_extraction(self):
        self.action.update(source='sheet.png', source_kind='AI-authored replacement key-pose sheet; not extracted from video', source_grid=[4,2])
        self.write_inputs()
        reg.register(self.repo)
        self.assertEqual(self.entries()[1]['sourceKind'], 'sprite-sheet-ai')
        self.assertIn('AI补制', self.entries()[1]['tags'])
        self.assertNotIn('视频提取', self.entries()[1]['tags'])

    def test_stale_animation_hash_fails_before_catalog_or_manifest_write(self):
        (self.runtime / 'run-body.png').write_bytes(b'changed')
        with self.assertRaises(ValueError):
            reg.register(self.repo)
        self.assertEqual(reg.read_json(self.repo / 'assets/catalog.json'), self.catalog)
        self.assertEqual(reg.read_json(self.repo / 'game/art/manifest.json'), self.manifest)

    def test_fx_keeps_independent_frame_count_and_rate(self):
        self.action['fx'] = self.layer('run-fx.png')
        self.action['fx'].update(frame_count=3, fps=20)
        self.write_inputs()
        reg.register(self.repo)
        body, fx = self.entries()[1:]
        self.assertEqual((body['frameCount'], body['fps']), (1,12))
        self.assertEqual((fx['frameCount'], fx['fps']), (3,20))

    def test_prune_is_explicit_narrow_and_preserves_references(self):
        for directory, names in ((self.runtime, ['old-body.png', 'old-body.png.import', 'projectile.png', 'notes.txt']),
                                 (self.game, ['old-body.png', 'old-body.png.import', 'orphan-fx.png.import', 'keep.png'])):
            for name in names:
                (directory / name).write_bytes(b'fixture')
        (self.runtime / 'nested').mkdir()
        (self.runtime / 'nested/other-body.png').write_bytes(b'fixture')
        outside = self.repo / 'assets/runtime/sprites/other-body.png'
        outside.write_bytes(b'outside')
        self.manifest['entries'].append({'src': 'assets/runtime/sprites/tide-picker-action36/protected-fx.png', 'dest': 'tide-picker-action36/protected-fx.png'})
        (self.runtime / 'protected-fx.png').write_bytes(b'protected')
        self.write_inputs()
        planned = reg.prune(self.repo)
        self.assertTrue(planned['dryRun'])
        self.assertEqual(len(planned['files']), 4)
        self.assertTrue((self.runtime / 'old-body.png').exists())
        applied = reg.prune(self.repo, apply=True)
        self.assertEqual(applied['files'], planned['files'])
        for name in planned['files']:
            self.assertFalse((self.repo / name).exists())
        for path in (outside, self.runtime / 'run-body.png', self.runtime / 'protected-fx.png',
                     self.runtime / 'old-body.png.import', self.runtime / 'nested/other-body.png',
                     self.runtime / 'projectile.png', self.game / 'keep.png'):
            self.assertTrue(path.exists(), path)

    def test_prune_protects_previous_synced_animation_and_rejects_escape(self):
        self.layer('previous-body.png')
        previous = copy.deepcopy(self.data)
        previous['actions']['run']['body']['texture'] = reg.URI + 'previous-body.png'
        reg.write_json(self.game / 'animations.json', previous)
        self.assertNotIn('assets/runtime/sprites/tide-picker-action36/previous-body.png', reg.prune(self.repo)['files'])
        self.action['body']['texture'] = reg.URI + '../outside-body.png'
        self.write_inputs()
        with self.assertRaises(ValueError):
            reg.prune(self.repo, apply=True)
        self.assertTrue((self.runtime / 'previous-body.png').exists())

    def test_redirected_task_directory_is_rejected_before_delete(self):
        with patch.object(reg, 'linked', side_effect=lambda path: path.name == reg.PREFIX):
            with self.assertRaises(ValueError):
                reg.prune(self.repo, apply=True)


if __name__ == '__main__':
    unittest.main(verbosity=2)
