//! Project links: the Help menu, the About dialog, the start screen and the title bar all open
//! these. DreamLab Canvas is based on PhotoCraft by the ArtCraft team (MIT OR Apache-2.0).

use serde_json::{Value, json};

use crate::DreamLabCanvasApp;

pub const GITHUB: &str = "https://github.com/ADNY101/dreamlab-canvas";
pub const ISSUES: &str = "https://github.com/ADNY101/dreamlab-canvas/issues";
/// Where the Feedback buttons go: the issue tracker.
pub const FEEDBACK: &str = ISSUES;

/// Help-menu link commands: (id, url). Labels live in `menus::UI_COMMANDS`.
pub const COMMANDS: &[(&str, &str)] = &[("help.github", GITHUB), ("help.reportIssue", ISSUES)];

pub fn url_for(id: &str) -> Option<&'static str> {
    COMMANDS.iter().find(|c| c.0 == id).map(|c| c.1)
}

/// Open `url` in the system browser (a new tab on the web) and note it in the status bar. Prefers
/// the platform `open_url` service (reliable on Windows/macOS/Linux); falls back to `ctx.open_url`.
pub fn open(app: &mut DreamLabCanvasApp, ctx: &egui::Context, url: &str) -> Value {
    let opened = app.services.open_url.as_ref().map(|f| f(url).is_ok()).unwrap_or(false);
    if !opened {
        ctx.open_url(egui::OpenUrl::new_tab(url));
    }
    let template = "Opened {url}";
    app.ui.status = crate::i18n::fmt(tl!(template), &[("url", url)]);
    json!({"url": url})
}

/// The prominent "Send Feedback" button (opens the issue tracker).
pub fn feedback_button(app: &mut DreamLabCanvasApp, ui: &mut egui::Ui, min_width: f32) -> egui::Response {
    let r = crate::widgets::primary_button(ui, tl!("Send Feedback"), min_width).on_hover_text(FEEDBACK);
    if r.clicked() {
        open(app, ui.ctx(), FEEDBACK);
    }
    r
}

/// "DreamLab Canvas on GitHub" as a link, centred. Clicks route through [`open`] (the
/// platform browser service) rather than `ui.hyperlink_to`, which uses the unreliable `ctx.open_url`.
pub fn link_row(app: &mut DreamLabCanvasApp, ui: &mut egui::Ui) {
    let t = crate::theme::Tokens::get(ui.ctx());
    let links = [(tl!("DreamLab Canvas on GitHub"), GITHUB)];
    let font = egui::FontId::proportional(12.5);
    let sep = "  ·  ";
    let width: f32 = links.iter().map(|(l, _)| ui.painter().layout_no_wrap((*l).into(), font.clone(), t.text).size().x).sum::<f32>()
        + 2.0 * ui.painter().layout_no_wrap(sep.into(), font.clone(), t.text).size().x;
    let mut clicked: Option<&str> = None;
    ui.horizontal(|ui| {
        ui.spacing_mut().item_spacing.x = 0.0;
        ui.add_space(((ui.available_width() - width) / 2.0).max(0.0));
        for (i, (label, url)) in links.iter().enumerate() {
            if i > 0 {
                ui.label(egui::RichText::new(sep).font(font.clone()).color(t.text_faint));
            }
            if ui.link(egui::RichText::new(*label).font(font.clone()).color(t.accent)).on_hover_text(*url).clicked() {
                clicked = Some(url);
            }
        }
    });
    if let Some(url) = clicked {
        open(app, ui.ctx(), url);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn links_open_through_the_platform_service() {
        // Issue #14: links (Help menu, Feedback button, start-page links) must open in the browser.
        // They route through the `open_url` service rather than the unreliable `ctx.open_url`.
        use std::sync::{Arc, Mutex};
        let opened: Arc<Mutex<Vec<String>>> = Arc::new(Mutex::new(Vec::new()));
        let rec = opened.clone();
        let services = crate::Services {
            open_url: Some(Box::new(move |u: &str| {
                rec.lock().unwrap().push(u.to_string());
                Ok(())
            })),
            ..Default::default()
        };
        let mut app = DreamLabCanvasApp::new(dreamlab_canvas_engine::Session::new(), services);
        let ctx = egui::Context::default();
        // Every Help-menu link id reaches the service with its URL.
        for (id, url) in COMMANDS {
            crate::menus::invoke(&mut app, &ctx, id, json!({})).unwrap();
            assert_eq!(opened.lock().unwrap().last().map(String::as_str), Some(*url), "{id}");
        }
        // The direct open() helper (Feedback button / start-page links) also uses it.
        open(&mut app, &ctx, FEEDBACK);
        assert_eq!(opened.lock().unwrap().last().map(String::as_str), Some(FEEDBACK));
    }

    #[test]
    fn help_menu_lists_links_then_separator_then_system_info_and_about() {
        let app = DreamLabCanvasApp::new(dreamlab_canvas_engine::Session::new(), Default::default());
        let help: Vec<String> = crate::menus::menu_items(&app).into_iter().filter(|i| i.path == ["Help"]).map(|i| i.id).collect();
        assert_eq!(help, ["help.github", "help.reportIssue", "---", "help.systemInfo", "help.about"]);
        for (id, _) in COMMANDS {
            assert!(crate::menus::is_live(id) && crate::menus::is_enabled(&app, id), "{id}");
        }
    }

    #[test]
    fn link_commands_open_their_urls() {
        let mut app = DreamLabCanvasApp::new(dreamlab_canvas_engine::Session::new(), Default::default());
        let ctx = egui::Context::default();
        for (id, url) in
            [("help.github", "https://github.com/ADNY101/dreamlab-canvas"), ("help.reportIssue", "https://github.com/ADNY101/dreamlab-canvas/issues")]
        {
            let r = crate::menus::invoke(&mut app, &ctx, id, serde_json::json!({})).unwrap();
            assert_eq!(r["url"], url);
            assert_eq!(app.ui.status, format!("Opened {url}"));
        }
    }
}
