# Summer Art Gallery

Static GitHub Pages deployment for `夏日美术馆-完整版1.html`.

The deployed page has been optimized from Claude's embedded bundle into a small `index.html` plus external static assets under `assets/bundle/`.

## Artwork Data

The page loads `assets/gallery-data.js` first. If that file is empty or missing, it falls back to the sample wired in `index.html` under `接入点 1 / SAMPLE_ARTWORKS`.

```js
{
  id: "pan-yueting-summer",
  student: "blue",
  authorName: "潘悦婷",
  title: "白衬衫与海风",
  medium: "Procreate · 数位绘画",
  year: 2026,
  note: "蓝色的夏天像水面一样发亮，人物停在风里，安静又清透。",
  img: "assets/bundle/pan-yueting-summer.jpg",
  imgPosition: "50% 50%",
  imgFit: "contain",
  mine: true
}
```

For the real batch, put source files under the workspace folder `assets/gallery`, then run:

```powershell
.\scripts\sync-gallery.ps1
```

Supported source layouts:

```text
assets/gallery/作者名/作品名.jpg
assets/gallery/分类名/作者名/作品名.jpg
```

The sync script copies images into `assets/bundle/gallery/` and writes `assets/gallery-data.js`.
