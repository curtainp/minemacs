;; -*- lexical-binding: t; -*-

(defvar +org-responsive-image-percentage 0.4)
(defvar +org-responsive-image-width-limits '(400 . 700)) ;; '(min . max)

(defun +org--responsive-image-h ()
  (when (derived-mode-p 'org-mode)
    (setq-local
     org-image-actual-width
     (list (max (car +org-responsive-image-width-limits)
                (min (cdr +org-responsive-image-width-limits)
                     (truncate (* (window-pixel-width)
                                  +org-responsive-image-percentage))))))))


(defun +parse-the-fun (str)
  "Parse the LaTeX environment STR.
  Return an AST with newlines counts in each level."
  (let (ast)
    (with-temp-buffer
      (insert str)
      (goto-char (point-min))
      (while (re-search-forward
              (rx "\\"
                  (group (or "\\" "begin" "end" "nonumber"))
                  (zero-or-one "{" (group (zero-or-more not-newline)) "}"))
              nil t)
        (let ((cmd (match-string 1))
              (env (match-string 2)))
          (cond ((string= cmd "begin")
                 (push (list :env (intern env)) ast))
                ((string= cmd "\\")
                 (let ((curr (pop ast)))
                   (push (plist-put curr :newline (1+ (or (plist-get curr :newline) 0))) ast)))
                ((string= cmd "nonumber")
                 (let ((curr (pop ast)))
                   (push (plist-put curr :nonumber (1+ (or (plist-get curr :nonumber) 0))) ast)))
                ((string= cmd "end")
                 (let ((child (pop ast))
                       (parent (pop ast)))
                   (push (plist-put parent :childs (cons child (plist-get parent :childs))) ast)))))))
    (plist-get (car ast) :childs)))


(defun +scimax-org-renumber-environment (orig-func &rest args)
  "A function to inject numbers in LaTeX fragment previews."
  (let ((results '())
        (counter -1))
    (setq results
          (cl-loop for (begin . env) in
                   (org-element-map (org-element-parse-buffer) 'latex-environment
                     (lambda (env)
                       (cons
                        (org-element-property :begin env)
                        (org-element-property :value env))))
                   collect
                   (cond
                    ((and (string-match "\\\\begin{equation}" env)
                          (not (string-match "\\\\tag{" env)))
                     (cl-incf counter)
                     (cons begin counter))
                    ((string-match "\\\\begin{align}" env)
                     (cl-incf counter)
                     (let ((p (car (+parse-the-fun env))))
                       ;; Parse the `env', count new lines in the align env as equations, unless
                       (cl-incf counter (- (or (plist-get p :newline) 0)
                                           (or (plist-get p :nonumber) 0))))
                     (cons begin counter))
                    (t
                     (cons begin nil)))))
    (when-let ((number (cdr (assoc (point) results))))
      (setf (car args)
            (concat
             (format "\\setcounter{equation}{%s}\n" number)
             (car args)))))
  (apply orig-func args))


(defun +scimax-toggle-latex-equation-numbering (&optional enable quite)
  "Toggle whether LaTeX fragments are numbered."
  (interactive)
  (if (or enable (not (get '+scimax-org-renumber-environment 'enabled)))
      (progn
        (advice-add 'org-create-formula-image :around #'+scimax-org-renumber-environment)
        (put '+scimax-org-renumber-environment 'enabled t)
        (unless quite (message "LaTeX numbering enabled.")))
    (advice-remove 'org-create-formula-image #'+scimax-org-renumber-environment)
    (put '+scimax-org-renumber-environment 'enabled nil)
    (unless quite (message "LaTeX numbering disabled."))))


(defun +scimax-org-inject-latex-fragment (orig-func &rest args)
  "Advice function to inject latex code before and/or after the equation in a latex fragment.
  You can use this to set \\mathversion{bold} for example to make
  it bolder. The way it works is by defining
  :latex-fragment-pre-body and/or :latex-fragment-post-body in the
  variable `org-format-latex-options'. These strings will then be
  injected before and after the code for the fragment before it is
  made into an image."
  (setf (car args)
        (concat
         (or (plist-get org-format-latex-options :latex-fragment-pre-body) "")
         (car args)
         (or (plist-get org-format-latex-options :latex-fragment-post-body) "")))
  (apply orig-func args))


(defun +scimax-toggle-inject-latex ()
  "Toggle whether you can insert latex in fragments."
  (interactive)
  (if (not (get '+scimax-org-inject-latex-fragment 'enabled))
      (progn
        (advice-add 'org-create-formula-image :around #'+scimax-org-inject-latex-fragment)
        (put '+scimax-org-inject-latex-fragment 'enabled t)
        (message "Inject latex enabled"))
    (advice-remove 'org-create-formula-image #'+scimax-org-inject-latex-fragment)
    (put '+scimax-org-inject-latex-fragment 'enabled nil)
    (message "Inject latex disabled")))


(defun me-org-extras-setup ()
  (add-hook 'window-configuration-change-hook
            #'+org--responsive-image-h)
  ;; Enable renumbering by default
  (+scimax-toggle-latex-equation-numbering t))


(provide 'me-org-extras)