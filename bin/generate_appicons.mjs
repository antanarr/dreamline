#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import sharp from 'sharp';

const root = process.cwd();
const appiconDir = path.join(root, 'Resources', 'Assets.xcassets', 'AppIcon.appiconset');
const master = path.join(appiconDir, 'AppIcon.png');

if (!fs.existsSync(master)) {
  console.error('Missing master 1024x1024 icon at', master);
  process.exit(1);
}

const specs = [
  // iPhone
  {idiom:'iphone', size:'20x20', scale:'2x', px:40, name:'iphone-notification-20@2x.png'},
  {idiom:'iphone', size:'20x20', scale:'3x', px:60, name:'iphone-notification-20@3x.png'},
  {idiom:'iphone', size:'29x29', scale:'2x', px:58, name:'iphone-settings-29@2x.png'},
  {idiom:'iphone', size:'29x29', scale:'3x', px:87, name:'iphone-settings-29@3x.png'},
  {idiom:'iphone', size:'40x40', scale:'2x', px:80, name:'iphone-spotlight-40@2x.png'},
  {idiom:'iphone', size:'40x40', scale:'3x', px:120, name:'iphone-spotlight-40@3x.png'},
  {idiom:'iphone', size:'60x60', scale:'2x', px:120, name:'iphone-app-60@2x.png'},
  {idiom:'iphone', size:'60x60', scale:'3x', px:180, name:'iphone-app-60@3x.png'},
  // iPad
  {idiom:'ipad', size:'20x20', scale:'1x', px:20, name:'ipad-notification-20.png'},
  {idiom:'ipad', size:'20x20', scale:'2x', px:40, name:'ipad-notification-20@2x.png'},
  {idiom:'ipad', size:'29x29', scale:'1x', px:29, name:'ipad-settings-29.png'},
  {idiom:'ipad', size:'29x29', scale:'2x', px:58, name:'ipad-settings-29@2x.png'},
  {idiom:'ipad', size:'40x40', scale:'1x', px:40, name:'ipad-spotlight-40.png'},
  {idiom:'ipad', size:'40x40', scale:'2x', px:80, name:'ipad-spotlight-40@2x.png'},
  {idiom:'ipad', size:'76x76', scale:'1x', px:76, name:'ipad-app-76.png'},
  {idiom:'ipad', size:'76x76', scale:'2x', px:152, name:'ipad-app-76@2x.png'},
  {idiom:'ipad', size:'83.5x83.5', scale:'2x', px:167, name:'ipad-pro-83.5@2x.png'},
  // marketing
  {idiom:'ios-marketing', size:'1024x1024', scale:'1x', px:1024, name:'AppIcon.png', marketing:true}
];

const images = [];

async function run(){
  for (const s of specs) {
    const out = path.join(appiconDir, s.name);
    if (!fs.existsSync(out)) {
      await sharp(master).resize(s.px, s.px).png().toFile(out);
    }
    images.push({idiom:s.idiom, size:s.size, scale:s.scale, filename:s.name});
  }
  const contents = { images, info:{version:1, author:'xcode'} };
  fs.writeFileSync(path.join(appiconDir, 'Contents.json'), JSON.stringify(contents, null, 2));
  console.log('Generated app icon renditions:', images.length);
}

run().catch(e=>{ console.error(e); process.exit(1); });
