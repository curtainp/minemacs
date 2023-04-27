;;; config.el -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Abdelhak Bougouffa

;; Personal info
(setq user-full-name "curtain"
      user-mail-address (concat "keleidscope" "@" "163" "." "com"))

;; Set the default GPG key ID, see "gpg --list-secret-keys"
;; (setq-default epa-file-encrypt-to '("XXXX"))

(setq
 ;; Set a theme for MinEmacs, supported themes include these from `doom-themes'
 ;; and `modus-themes'.
 minemacs-theme 'doom-one ; `doom-one' is a dark theme, `doom-one-light' is the light one
 ;; Set Emacs fonts, some good choices include:
 ;; - Cascadia Code
 ;; - Fira Code, FiraCode Nerd Font
 ;; - Iosevka, Iosevka Fixed Curly Slab
 ;; - IBM Plex Mono
 ;; - JetBrains Mono
 minemacs-fonts
 '(:font-family "JetBrains Mono"
   :font-size 16
   :variable-pitch-font-family "IBM Plex Serif"
   :variable-pitch-font-size 16))

(+deferred!
 ;; Auto enable Eglot in supported modes using `+eglot-auto-enable' (from the
 ;; `me-prog' module). You can use `+lsp-auto-enable' instead to automatically
 ;; enable LSP mode in supported modes (from the `me-lsp' module).
 (+eglot-auto-enable))

;; Module: `me-org' -- Package: `org'
(with-eval-after-load 'org
  ;; Set Org-mode directory
  (setq org-directory "~/workspace/docs/org/" ; let's put files here
        org-default-notes-file (concat org-directory "inbox.org"))

  (setq org-export-headline-levels 5)

  (require 'tempo)

  ;; Your Org files to include in the agenda
  (setq org-agenda-files
        (mapcar
         (lambda (f) (concat org-directory f))
         '("inbox.org"
           "agenda.org"
           "projects.org"))))

;; Module: `me-notes' -- Package: `org-roam'
(with-eval-after-load 'org-roam
  (setq org-roam-directory (concat org-directory "slip-box/")
        org-roam-db-location (concat org-roam-directory "org-roam.db"))

  ;; Register capture template (via Org-Protocol)
  ;; Add this as bookmarklet in your browser
  ;; javascript:location.href='org-protocol://roam-ref?template=r&ref=%27+encodeURIComponent(location.href)+%27&title=%27+encodeURIComponent(document.title)+%27&body=%27+encodeURIComponent(window.getSelection())
  (setq org-roam-capture-ref-templates
        '(("r" "ref" plain "%?"
           :if-new (file+head "web/%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+created: %U\n\n${body}\n")
           :unnarrowed t))))
