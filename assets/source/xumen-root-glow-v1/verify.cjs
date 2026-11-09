// Reuse the measured local-edit comparison with the E01 world view and bounds.
const {spawnSync}=require('node:child_process'),path=require('node:path');
const r=spawnSync(process.execPath,[path.resolve(__dirname,'../xumen-ecology-niches-v1/verify.cjs'),'--e01'],{stdio:'inherit'});process.exit(r.status??1);
