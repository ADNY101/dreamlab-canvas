//! Windows only: embed the app icon and version info (VERSIONINFO) into `dreamlab-canvas.exe`.
//!
//! On every other target this does nothing. A missing resource compiler is a warning, so a
//! cross-compile from macOS or Linux still links, unless `DREAMLAB_CANVAS_REQUIRE_WINRES=1` (set by the
//! release workflow) turns it into an error.

fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-changed=../../assets/app-icon/dreamlab-canvas.ico");
    println!("cargo:rerun-if-env-changed=DREAMLAB_CANVAS_REQUIRE_WINRES");
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() != Ok("windows") {
        return;
    }
    let mut res = winresource::WindowsResource::new();
    res.set_icon("../../assets/app-icon/dreamlab-canvas.ico")
        .set("ProductName", "DreamLab Canvas")
        .set("FileDescription", "DreamLab Canvas image editor")
        .set("CompanyName", "DreamLab")
        .set("LegalCopyright", "Copyright (c) the DreamLab Canvas authors. MIT OR Apache-2.0.")
        .set("OriginalFilename", "dreamlab-canvas.exe")
        .set("InternalName", "dreamlab-canvas");
    if let Err(e) = res.compile() {
        if std::env::var_os("DREAMLAB_CANVAS_REQUIRE_WINRES").is_some() {
            panic!("embedding Windows resources failed: {e}");
        }
        println!("cargo:warning=dreamlab-canvas.exe built without icon/version resources: {e}");
    }
}
