# Format overview

External bytes enter DreamLab Canvas through four main paths:

- `dreamlab-canvas-psd` parses and writes PSD and PSB structures.
- `dreamlab-canvas-codecs` decodes and encodes flat raster formats.
- `dreamlab-canvas-format` loads and saves the native `.pcraft` bundle.
- `dreamlab-canvas-affinity` reads native Affinity documents (`.af`, `.afdesign`, `.afphoto`, `.afpub`): layers, artboards, vectors, text, images and masks; it does not write them.

`dreamlab-canvas-io` maps PSD and flat images into the document model and exports documents back to those formats. It is the integration layer; parsing limits remain the responsibility of the underlying format crates.

Formats are a primary security boundary. File extension is not a trust signal, metadata can be attacker-controlled, and small compressed inputs can declare very large decoded outputs. Callers should use the bounded default APIs and preserve errors rather than retrying with unlimited limits.

See [PSD and PSB](psd-psb.md), [Raster formats](raster-formats.md), [SVG](svg.md), [Affinity documents](affinity.md), and [The `.pcraft` format](pcraft.md). Cross-format hardening guidance is in [Parser hardening](../security/parser-hardening.md).
