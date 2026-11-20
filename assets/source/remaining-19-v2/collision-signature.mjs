import crypto from 'node:crypto';
export function collisionSignature(scene) {
 const nodes=scene.replaceAll('\r\n','\n').match(/\[node[^\n]+ type="(?:StaticBody2D|Collision\w+)"[^\n]*\][\s\S]*?(?=\n\[|$)/g)??[];
 return crypto.createHash('sha256').update(nodes.map(n=>n.trim()).join('\n')).digest('hex');
}
