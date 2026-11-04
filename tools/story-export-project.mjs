import { cpSync, existsSync, lstatSync, mkdirSync, readFileSync, readdirSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import path from 'node:path';

export const STORY_SCENE = 'res://content/story/main.tscn';

export function storyProjectSettings(text) {
  const application = /(^\[application\]\s*$)([\s\S]*?)(?=^\[|$(?![\s\S]))/m;
  const section = text.match(application);
  if (!section || !/^run\/main_scene="[^"]+"\s*$/m.test(section[2])) {
    throw new Error('Project has no recognizable application main scene.');
  }
  return text.replace(application, (_match, heading, body) => heading +
    body.replace(/^run\/main_scene="[^"]+"/m, `run/main_scene="${STORY_SCENE}"`));
}

export function prepareStoryProject(game) {
  game = path.resolve(game);
  const build = path.join(game, 'build');
  mkdirSync(build, { recursive: true });
  if (lstatSync(build).isSymbolicLink() || realpathSync(build).toLowerCase() !== build.toLowerCase()) {
    throw new Error('Story build directory must not be linked.');
  }
  const project = path.join(build, 'story-export-project');
  if (existsSync(project)) {
    if (lstatSync(project).isSymbolicLink() || path.dirname(realpathSync(project)).toLowerCase() !== realpathSync(build).toLowerCase()) {
      throw new Error('Unsafe isolated story project directory.');
    }
    rmSync(project, { recursive: true });
  }
  const original = readFileSync(path.join(game, 'project.godot'), 'utf8');
  // Copy real files, never hardlink project/settings/import artifacts into the source tree.
  // Preserve imported resource bytes and timestamps, but avoid editor and export cache state.
  mkdirSync(project);
  const filter = file => {
    const relative = path.relative(path.toNamespacedPath(game), path.toNamespacedPath(file));
    const parts = relative.split(path.sep);
    if (parts[0] === 'build' || parts[0] === '.git') return false;
    if (parts[0] !== '.godot' || parts.length === 1) return true;
    return ['imported', 'global_script_class_cache.cfg', 'uid_cache.bin', '.gdignore'].includes(parts[1]);
  };
  for (const name of readdirSync(game)) {
    const source = path.join(game, name);
    if (filter(source)) cpSync(source, path.join(project, name), { recursive: true, preserveTimestamps: true, filter });
  }
  writeFileSync(path.join(project, 'project.godot'), storyProjectSettings(original));
  if (readFileSync(path.join(game, 'project.godot'), 'utf8') !== original) {
    throw new Error('Source project settings changed while preparing chapter export.');
  }
  return project;
}
