const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const manifest = JSON.parse(fs.readFileSync(path.join(root, "manifest.json"), "utf8"));
const profile = JSON.parse(fs.readFileSync(path.join(root, "project-profile.json"), "utf8"));
const atlasSource = fs.readFileSync(path.join(root, "src", "atlas.js"), "utf8");
const errors = [];

const ids = new Set();
for (const screen of manifest) {
  if (!screen.id || !screen.board || !screen.title || !screen.template || !screen.role) errors.push(`Screen thiếu field bắt buộc: ${JSON.stringify(screen)}`);
  if (ids.has(screen.id)) errors.push(`Screen ID trùng: ${screen.id}`);
  ids.add(screen.id);
  if (!profile.roles.some(role => role.code === screen.role)) errors.push(`Role không tồn tại: ${screen.id} -> ${screen.role}`);
  if (!atlasSource.includes(`case "${screen.template}"`)) errors.push(`Template chưa được render: ${screen.template}`);
}

const boardCounts = manifest.reduce((result, screen) => ({ ...result, [screen.board]: (result[screen.board] || 0) + 1 }), {});
if (manifest.length < 30) errors.push(`Atlas chưa đủ phạm vi: ${manifest.length} màn hình`);

if (errors.length) {
  process.stderr.write(errors.map(error => `ERROR: ${error}`).join("\n") + "\n");
  process.exit(1);
}

process.stdout.write(JSON.stringify({ screens: manifest.length, boards: boardCounts, roles: profile.roles.map(role => role.code) }, null, 2) + "\n");
