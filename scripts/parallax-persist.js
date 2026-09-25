/**
 * parallax-persist
 * ---------------------------------------------------------------------------
 * 让博客的视差背景壁纸“只按时间自动轮换”，切换页面（pjax 无刷新跳转）时保持不变，
 * 并正确预加载/预解码壁纸，避免切换时卡顿。
 *
 * 主题（volantis）默认行为：
 *   - 首次加载时调用 parallax()，用 setInterval 每隔 plugins.parallax.duration
 *     毫秒切换一张壁纸；
 *   - 同时把 parallax 注册进 pjax 回调：
 *       volantis.pjax.send(() => clearInterval(IntervalParallax), "clearIntervalParallax");
 *       volantis.pjax.push(parallax);
 *     于是每次 pjax 切页都会：先清掉定时器，再立刻 next_parallax() 切到下一张，
 *     并重新开始计时 —— 结果就是“一切页面壁纸就变”。
 *   - 自带的“缓存下一张”用 fetch(url + "?t=" + Date.now())，带时间戳导致 URL 每次不同，
 *     命中不了 <img> 的缓存，等于没预加载，切换时现场下载就会卡一下。
 *
 * 处理办法：
 *   1. 删除上面的两处 pjax 注册，只保留首次加载创建的定时器；
 *   2. 关掉无效的 fetch 缓存；
 *   3. 注入一段预加载脚本：用 new Image() 预加载并用 decode() 预解码所有壁纸，
 *      空闲时逐张加载，避免占满首屏带宽。
 *
 * 相关配置（_config.volantis.yml）：
 *   plugins.parallax.enable: true
 *   plugins.parallax.duration: 100000   # 每张壁纸停留毫秒数（这里 100 秒）
 *   plugins.pjax.cover: true            # 必须为 true，否则切页会重建封面
 */

'use strict';

const PRELOAD_MARK = 'parallax-persist: 预加载壁纸';

const PRELOAD_SCRIPT = `<script>
/* ${PRELOAD_MARK}：用真实 URL 预加载并预解码，避免切换卡顿 */
(function () {
  if (typeof imgs === "undefined" || !imgs || !imgs.length) return;
  var loaded = Object.create(null);
  function load(src, decode) {
    if (!src || loaded[src]) return;
    loaded[src] = 1;
    var img = new Image();
    if (decode) img.decoding = "async";
    img.src = src;
    if (decode && img.decode) {
      try { img.decode().catch(function () {}); } catch (e) {}
    }
  }
  // 当前第一张立即加载并解码
  load(imgs[0], true);
  // 其余壁纸在浏览器空闲时逐张预加载
  var rest = imgs.slice(1);
  var idle = window.requestIdleCallback ||
    function (cb) { return setTimeout(function () { cb({ timeRemaining: function () { return 50; } }); }, 300); };
  (function next() {
    if (!rest.length) return;
    load(rest.shift(), true);
    idle(next, { timeout: 2000 });
  })();
})();
</script>`;

hexo.extend.filter.register('after_render:html', function (str) {
  if (!str || str.indexOf('IntervalParallax') === -1) return str;

  let changed = false;

  // 1) 删除 pjax:send 时清除定时器的回调（否则每次切页计时都会重置）
  const sendRe = /volantis\.pjax\.send\(\s*\(\s*\)\s*=>\s*\{\s*clearInterval\(\s*IntervalParallax\s*\)\s*;?\s*\}\s*,\s*["']clearIntervalParallax["']\s*\)\s*;?/;
  if (sendRe.test(str)) {
    str = str.replace(sendRe, '/* parallax-persist: 保留定时器，切页不重置 */');
    changed = true;
  }

  // 2) 删除 pjax:complete 时重载 parallax 的回调（否则每次切页立刻换下一张）
  const pushRe = /volantis\.pjax\.push\(\s*parallax\s*\)\s*;?/;
  if (pushRe.test(str)) {
    str = str.replace(pushRe, '/* parallax-persist: 壁纸只按时间轮换，pjax 切页不重载 */');
    changed = true;
  }

  // 3) 关闭主题自带的无效 fetch 缓存（带 ?t= 时间戳，命中不了图片缓存）
  if (/Parallax\.cache\s*=\s*1\s*;/.test(str)) {
    str = str.replace(/Parallax\.cache\s*=\s*1\s*;/, 'Parallax.cache = 0; /* parallax-persist: 改用下列预加载 */');
    changed = true;
  }

  // 4) 注入真正的预加载脚本（只注入一次，放在 </body> 前，此时 imgs 已定义）
  if (changed && str.indexOf(PRELOAD_MARK) === -1 && str.indexOf('</body>') !== -1) {
    str = str.replace('</body>', PRELOAD_SCRIPT + '\n</body>');
  }

  if (changed) {
    hexo.log.debug('parallax-persist: 已优化 parallax 的 pjax 行为与预加载');
  }
  return str;
}, 20);
