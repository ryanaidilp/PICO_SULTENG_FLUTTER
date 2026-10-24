#!/usr/bin/env node
// Lottie .json <-> dotLottie .lottie, with the official LottieFiles library
// (@dotlottie/dotlottie-js). Install once: npm install --prefix <this dir>
//
//   node dotlottie.mjs pack <a.json> [b.json ...] -o <out.lottie> [--v1]
//   node dotlottie.mjs unpack <in.lottie> <out_dir>
//   node dotlottie.mjs info <in.lottie>
//
// pack writes dotLottie v2 (manifest.json + a/<id>.json); --v1 writes the
// older layout (animations/<id>.json) for players that only read v1. The
// Flutter lottie package reads both.
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { basename, join } from 'node:path';
import {
  DotLottie,
  DotLottieV1,
  getAnimations,
  getManifest,
  validateDotLottie,
} from '@dotlottie/dotlottie-js';

const [cmd, ...args] = process.argv.slice(2);

async function pack() {
  const v1 = args.includes('--v1');
  const o = args.indexOf('-o');
  if (o < 0 || !args[o + 1]) throw new Error('pack needs -o <out.lottie>');
  const out = args[o + 1];
  const inputs = args.filter((a, i) => a.endsWith('.json') && i !== o + 1);
  if (inputs.length === 0) throw new Error('pack needs at least one .json');
  const lottie = v1 ? new DotLottieV1() : new DotLottie();
  for (const [i, file] of inputs.entries()) {
    lottie.addAnimation({
      id: basename(file, '.json'),
      data: JSON.parse(await readFile(file, 'utf8')),
      ...(i === 0 ? { defaultActiveAnimation: true } : {}),
    });
  }
  await lottie.build();
  const bytes = new Uint8Array(await lottie.toArrayBuffer());
  const check = await validateDotLottie(bytes);
  if (!check.success) throw new Error(`invalid .lottie: ${check.error}`);
  await writeFile(out, bytes);
  const json = (await Promise.all(inputs.map((f) => readFile(f)))).reduce((n, b) => n + b.length, 0);
  console.log(`wrote ${out} (${bytes.length} bytes; json ${json} bytes, ${Math.round((100 * bytes.length) / json)}%)`);
}

async function unpack() {
  const [file, dir] = args;
  if (!file || !dir) throw new Error('unpack needs <in.lottie> <out_dir>');
  const anims = await getAnimations(new Uint8Array(await readFile(file)), { inlineAssets: true });
  await mkdir(dir, { recursive: true });
  for (const [id, data] of Object.entries(anims)) {
    const out = join(dir, `${id}.json`);
    await writeFile(out, JSON.stringify(data));
    console.log(`wrote ${out}`);
  }
}

async function info() {
  const bytes = new Uint8Array(await readFile(args[0]));
  const check = await validateDotLottie(bytes);
  console.log(JSON.stringify({ valid: check.success, error: check.error, manifest: await getManifest(bytes) }, null, 2));
  if (!check.success) process.exitCode = 1;
}

const commands = { pack, unpack, info };
if (!commands[cmd]) {
  console.error('usage: dotlottie.mjs pack|unpack|info ... (see the header of this file)');
  process.exit(64);
}
commands[cmd]().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
