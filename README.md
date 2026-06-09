# 光屿 Guangyu

补光 · 修图 · 一键发小红书 —— 一个好看、现代、有特色的补光修图 App。

视觉风格 **Aurora Glass（极光玻璃）**：深空蓝紫渐变底色 + 缓慢游动的极光光晕 +
毛玻璃卡片。刻意区别于市面千篇一律的粉色补光灯。

## 核心流程

1. **从相册导入** 一张照片（`image_picker`）
2. 在 **编辑器** 里给照片贴可爱的发光小贴纸（拖动 / 双指缩放 / 旋转 / 删除）
3. 叠加 **补光色卡**（蜜桃 / 极光 / 梦紫 / 暖阳 / 薄荷），用滑杆调光效强度
4. **一键导入小红书**：画布渲染成图，唤起系统分享并预填文案

## Hero 渐变动画

- 首页模板 / 色卡 → 编辑器画布：渐变色块平滑放大过渡
- 贴纸面板里的贴纸 → 画布：图标「飞」到照片上（飞行结束后释放 Hero tag 以便复用）

## 代码结构

```
lib/
├── main.dart                       入口 + 主题挂载
├── theme/app_theme.dart            Aurora Glass 设计系统（色彩 / 渐变 / 文字）
├── widgets/
│   ├── aurora_background.dart       会呼吸的极光背景（CustomPainter）
│   ├── glass.dart                   毛玻璃卡片 + 渐变按钮
│   ├── sticker_glyph.dart           发光矢量贴纸字形
│   ├── sticker_picker_sheet.dart    分类贴纸选择面板（Hero 飞行起点）
│   └── page_transitions.dart        淡入缩放路由
├── models/
│   ├── photo_source.dart            画布素材：模板渐变 或 相册图片
│   └── sticker.dart                 贴纸资源 / 已放置贴纸
├── data/
│   ├── sticker_catalog.dart         30 个发光矢量贴纸，5 个分类
│   └── templates.dart              灵感模板（渐变 + 文案 + 预置贴纸）
└── screens/
    ├── home_screen.dart             首页：导入 / 模板墙 / 补光色卡
    ├── editor_screen.dart           ★ 核心：画布 + 贴纸 + 补光 + 导出
    └── export_sheet.dart            一键导入小红书
```

> 贴纸采用**设计过的发光矢量图标**（非系统 emoji）——跨平台渲染一致，且更有品牌感。

## 运行

```bash
flutter pub get
flutter run        # iOS 需相册权限，已在 Info.plist 配好
```

## 后续可做

- 真实「补光灯」全屏发光模式（爱心瞳孔等灯形）
- 贴纸图层顺序调整、文字贴纸、自由画笔
- 小红书深度链接直达发布页 / 保存到相册
- 用户自定义收藏色卡
