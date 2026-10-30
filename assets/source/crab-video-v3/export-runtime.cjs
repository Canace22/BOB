// Reproducible export. Install sharp or provide NODE_PATH.
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');
const output = path.resolve(__dirname, '../../runtime/sprites/crab-video-v3');
const actions = ['01_idle', '02_claw_slam', '04_sweep', '06_shell_shake', '07_body_slam', '08_retreat', '09_sink_fade'];
(async () => {
  fs.mkdirSync(output, {recursive: true});
  for (const id of actions) {
    // Preserve accepted sprite resolution. Half-size exports visibly blurred the shell.
    fs.copyFileSync(path.join(__dirname, 'sheets', id + '.png'), path.join(output, id + '.png'));
  }
  for (const id of ['impact_dust', 'shell_turn']) {
    await sharp(path.join(__dirname, 'effects', id + '.png')).resize(1024, 256).png().toFile(path.join(output, id + '.png'));
  }
  await sharp(path.join(__dirname, 'environment.png')).resize({width: 1480}).png().toFile(path.join(output, 'environment.png'));
  console.log('Exported seven actions, two effects and environment');
})().catch(error => {console.error(error); process.exitCode = 1;});
