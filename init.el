;;; * SOME HELPFUL COMMENTS
;; You can fold the sections within this buffer by using C-TAB
;;
;; For getting help on keybindings, there is the standard command
;; for listing the current mode mappings: C-h m
;; but also helm-descbinds: <f5>-d
;; and discover-my-major: C-h j
;; use-package introduces describe-personal-keybindings. Also, there is
;;    use-package-enable-imenu-support which adds use-package locations
;;    to imenu: <f5>-i

(add-hook 'emacs-startup-hook
          (lambda ()
            (message "Emacs ready in %s with %d garbage collections."
                     (format "%.2f seconds"
                             (float-time
                              (time-subtract after-init-time before-init-time)))
                     gcs-done)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; * Basic emacs configuration
;;; ** configuration of some standard Emacs settings
;;; *** User related
(setq user-full-name "Derek Feichtinger")
(setq user-mail-address "derek.feichtinger@psi.ch")

;;; *** File and directory related settings
;; Customizations done with the Emacs customization system shall be
;; saved to and loaded from this separate file, so that they can be
;; easily distinguished from our init files.
(setq custom-file "~/.emacs-custom.el")
(when (not (file-exists-p custom-file))
  (write-region ";; Emacs customization file" nil custom-file))
(load custom-file)

;; Put autosave files (i.e. #foo#) in one place, *not* scattered all
;; over the file system!
(defvar autosave-dir
  (concat "~/.emacs-autosaves/"))
(make-directory autosave-dir t)
(setq auto-save-file-name-transforms `((".*" ,autosave-dir t)))

;; Put backup files (ie foo~) in one place. (The
;; backup-directory-alist list contains regexp=>directory mappings;
;; filenames matching a regexp are backed up in the corresponding
;; directory. Emacs will mkdir it if necessary.)
(defvar backup-dir "~/.emacs-doc-backups/")
(setq backup-directory-alist (list (cons ".*" backup-dir)))

;;; *** minibuffer related
;; save the minibuffer history between sessions
(savehist-mode 1)
(setq history-length 120)

;;; *** other basic emacs settings
;; don't show the emacs default splash screen at start
(setq inhibit-splash-screen t)

;; I don't need the toolbar. It wastes screen space
(tool-bar-mode -1)

;; display column numbers in the mode line
(setq column-number-mode t)

;; yes or no questions to be answered by simple y/n
(fset 'yes-or-no-p 'y-or-n-p)

;; make some by default disabled features active
;; make the narrow to region and upcase commands active
(put 'narrow-to-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)

;; TODO: check for line-number-display-limit-width
;; increase emacs threshold for displaying line numbers in files with huge line width
;; from https://emacs.stackexchange.com/questions/3824/what-piece-of-code-in-emacs-makes-line-number-mode-print-as-line-number-i
(setq line-number-display-limit-width 2000000)

;; when using C-u C-SPC, let each following C-SPC again pop the mark
(setq set-mark-command-repeat-pop t)

;; make mouse middle click paste at point and not at mouse pointer
(setq mouse-yank-at-point t)

;; I would like to have time stamps in Org to use English day names
(setq system-time-locale "en_US.UTF-8")

;;; ** ibuffer
(setq ibuffer-saved-filter-groups
      '(("home"
	 ("Org" (or (mode . org-mode)
		    (mode . org-agenda-mode)))
	 ("Dired" (mode . dired-mode))
	 ("Mail" (or (mode . mu4e-compose-mode)
		     (mode . mu4e-headers-mode)))
	 ("emacs-config" (filename . ".emacs.d\\/.*\\.el"))
	 ("Emacs std buffers" (or (name . "\\*scratch\\*")
				  (name . "\\*Messages\\*")
				  (name . "\\*Calendar\\*")
				  (name . "\\*Backtrace\\*")))
	 ("Help" (or (name . "\\*Help\\*")
		     (name . "\\*Apropos\\*")
		     (name . "\\*info\\*")
		     (mode . Man-mode)))
	 ("Magit" (or (name . "magit: .*")
		      (name . "magit-.*")))
	 )))

(add-hook 'ibuffer-mode-hook
	  '(lambda ()
	     (ibuffer-switch-to-saved-filter-groups "home")))

;;; ** TRAMP - working with remote buffers
;; good tips on the emacs wiki: http://www.emacswiki.org/emacs/TrampMode
;; tramp definition for ensuring that the SSH control master
;; connections use the same path I have defined in my local
;; ssh configuration
(setq tramp-ssh-controlmaster-options
      (concat "-o ControlMaster=auto"
	      " -o ControlPath='~/.ssh/control/%%h_%%p_%%r'"
	      " -o ControlPersist=no"))

;; TRAMP env configuration:
;; - I want that tramp uses by preference the path that the remote
;;   user has defined (use 'tramp-own-remote-path). I defined it this
;;   way to be able and profit from newer versions of git installed in
;;   anaconda, so I could use magit on the remote host.
;; - TRAMP sessions will have the INSIDE_EMACS env variable set, but
;;   it only gets set after .profile on the remote host has run, so it
;;   cannot be used for a case distinction within .profile. But TERM=dumb
;;   is set from the start.
(eval-after-load 'tramp
  (lambda ()
    (setq tramp-remote-path (cons 'tramp-own-remote-path tramp-remote-path))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ** dired - directory navigation
;; default target for dired cp is dir in other displayed dired buffer
(setq dired-dwim-target t)

;; dired ls to use SI units (k=1000) and long date format
(setq dired-listing-switches "-al --si --time-style long-iso")

;; set a faster option for producing dired buffers from find-ls
(setq find-ls-option '("-exec ls -ld {} \\+" . "-ld"))

;; dired-x offers guess shell command" for executing commands using "!"
;; inside of dired. q.v.
;; http://www.masteringemacs.org/articles/2014/04/10/dired-shell-commands-find-xargs-replacement/
;; commands will be run against all marked files. The command can contain "?" or
;; "*" as placeholder, where "*" is just expanded to all marked files, while "?"
;; results in each file being singly given to the command.
(add-hook 'dired-load-hook
          (lambda ()
            (load "dired-x")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; * Helper functions and macros supporting configuration
;; function by xuchunyang to remove all advising from a function
;; https://emacs.stackexchange.com/questions/24657/unadvise-a-function-remove-all-advice-from-it
(defun dfeich-advice-unadvice (sym)
  "Remove all advices from symbol SYM."
  (interactive "aFunction symbol: ")
  (advice-mapc (lambda (advice _props) (advice-remove sym advice)) sym))

;;; * PACKAGE MANAGER CONFIGURATION and USE-PACKAGE

;; initialize the packages that have been installed by the emacs
;; package manager (else they get initialized after init has run)
;; package-initialize will extend the load path for each package and
;; pull in the package's autoloads.
(require 'package)

;; this line may be needed soon: 2019-08 https://irreal.org/blog/?p=8243
;; (when (and (>= libgnutls-version 30603)
;; 	   (version<= emacs-version "26.2"))
;;   (setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3"))
;;
;; also look at documentation of ghub-use-workaround-for-emacs-bug
(let* ((no-ssl-flag (not (gnutls-available-p)))
       (proto (if no-ssl-flag "http" "https")))
  (add-to-list 'package-archives
	       (cons "melpa" (concat proto "://melpa.org/packages/")) t)
  (add-to-list 'package-archives
	       (cons "org" (concat proto "://orgmode.org/elpa/")) t)
  )

;; disable the default initialization that would run after init.el has been
;; loaded (prevent loading twice, since I am doing it explicitely next). This
;; is now obsolete, since package-initialize will set it, too
(setq package-enable-at-startup nil)

;; package initialize activates all packages (adds package paths to
;; load-path and loads the autoloads files found in a package)
(package-initialize)


;; bootstrap use-package, if we do not yet have it
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; report use-package loading and configuration details
(setq use-package-verbose t)

;; make imenu also find use-package definitions
(setq use-package-enable-imenu-support t)

;; (setq use-package-debug t)

(require 'use-package)

;; paradox is a nicer package browser than the default
(use-package paradox :ensure t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; * Completion frameworks

;; use ido mode for buffer and file selections inside of the minibuffer. It
;; does a nice job of fuzzy matching
(use-package ido
  :ensure t
  :config (progn
	    (ido-mode t)
	    (setq ido-enable-flex-matching t)
	    (use-package flx-ido
	      :ensure t
	      :config
	      (flx-ido-mode 1))))

;; smex provides the matching for choosing emacs commands in the minibuffer
;; (i.e. when one does an M-x <somecommand>)
;; setup smex for flexible command matching in the mini-buffer
(use-package smex
  :ensure t
  :bind (("M-x" . smex)
	 ("M-X" . smex-major-mode-commands)
	 ("C-c M-x" . execute-extended-command)
	 ;; on my laptop <print> is convenient to reach
	 ("<print>" . smex)))


;; company offers the main completion mechanism when working inside of a
;; buffer. Completion candidates will depend on the functions defined for
;; each type of buffer
;; http://company-mode.github.io/
;;
;; if completion does not work, try to run company-complete-common
;; interactively at the same buffer position.
(use-package company
  :ensure t
  ;; company should be active from the beginning
  :demand t
  :config (progn
	    (setq company-global-modes
		  '(c-mode
		    emacs-lisp-mode
		    lisp-interaction-mode
		    mu4e-compose-mode
		    org-mode
		    puppet-mode
		    python-mode
		    yaml-mode))
	    (global-company-mode 1)

	    ;; this adds documentation popups for company mode. It uses the
	    ;; pos-tip package
	    (use-package company-quickhelp
	      :ensure t
	      :config (progn (company-quickhelp-mode 1)
			     (setq company-quickhelp-delay 1.0)))

	    ;; do not downcase the candidates. This is important
	    ;; for preserving WikiWords, etc. in programming.
	    (setq company-dabbrev-downcase nil))
  :bind (:map company-active-map
	      ;; I do not want that return completes the selection. This gets in
	      ;; the way when I do not want to select anything, but just type a
	      ;; new-line.
	      ("<S-return>" . company-complete-selection)
	      ("<return>" . nil)
	      ("RET" . nil)))


;; helm is a great framework for all kinds of narrowing down selections it
;; powers a lot of highly useful extensions
(use-package helm
  :ensure t)

(use-package helm-config
  :demand t
  :config (progn
	    ;; extend helm for org headings with the clock-in action
	    (defun dfeich-helm-org-clock-in (marker)
	      "Clock in and out of the item at MARKER"
	      (with-current-buffer (marker-buffer marker)
		(goto-char (marker-position marker))
		(org-clock-in)
		(org-clock-out))
	      (when (eq major-mode 'org-agenda-mode)
		(org-agenda-redo)))
	    (eval-after-load 'helm-org
	      '(nconc helm-org-headings-actions
		      (list
		       (cons "Clock into task" #'dfeich-helm-org-clock-in))))

	    (defun dfeich-helm-info-localmode ()
	      "Define which helm index info to use based on the current mode."
	      (interactive)
	      (require 'helm-info)
	      (case major-mode
		('org-mode (helm-info-org))
		('emacs-lisp-mode (helm-info-elisp))
		('magit-status-mode (helm-info-magit))
		('mu4e-headers-mode (info "mu4e"))
		('mu4e-view-mode (info "mu4e"))
		('makefile-gmake-mode (helm-info-make))
		('Info-mode
		 (let*
		     ((nodename (file-name-sans-extension
				 (file-name-nondirectory Info-current-file)))
		      (helmcmd (intern-soft (concat "helm-info-" nodename))))
		   (cond
		    ((equal nodename "dir") (helm-info))
		    (helmcmd (funcall-interactively helmcmd))
		    (t (message "No helm command helm-info-%s" nodename)))))
		(t (progn (message  "No helm info pre-configured for this mode (%s)"
				    major-mode)
			  (helm-info))))))
  
  :bind (("<f5> <f5>" . helm-org-agenda-files-headings)
	 ("<f5> <f6>" . helm-bookmarks)
	 ("<f5> a" . helm-apropos)
	 ("<f5> A" . helm-apt)
	 ("<f5> b" . helm-buffers-list)
	 ("<f5> B" . helm-bibtex)
	 ("<f5> c" . helm-colors)
	 ("<f5> f" . helm-find-files)
	 ("<f5> g" . helm-org-rifle)
	 ("<f5> G" . helm-org-rifle-directories)
	 ("<f5> i" . helm-semantic-or-imenu)
	 ("<f5> k" . helm-show-kill-ring)
	 ("<f5> K" . helm-execute-kmacro)
	 ("<f5> l" . helm-locate)
	 ;; ( "<f5> m" . helm-man-woman)
	 ("<f5> m" . dfeich-show-manpage)
	 ("<f5> o" . helm-occur)
	 ("<f5> p" . helm-list-emacs-process)
	 ("<f5> r" . helm-resume)
	 ("<f5> R" . helm-register)
	 ("<f5> t" . helm-top)
	 ("<f5> u" . helm-ucs)
	 ("<f5> x" . helm-M-x)
	 ;; <f6> based bindings
	 ("<f6> G" .  helm-google-suggest)
	 ("<f6> i" .  dfeich-helm-info-localmode)
	 ("<f6> I" .  helm-info)
	 ("<f6> l" .  helm-info-elisp)))

(defmacro dfeich-helm-add-action-to-sourcefn (srcfn name func)
  "Adds an action to a helm source-producing function through advice."
  (let ((advfn (make-symbol (concat "dfeich-" (symbol-name srcfn)))))
    ;; The default selection is given in the first arg
    `(progn (defun ,advfn (origfn &rest args)
	      ;; (message (pp-to-string args))
	      (let* ((source (apply (list origfn (car args))))
		     (actions (alist-get 'action source)))
		(setf (alist-get 'action source)
		      (append actions (list (cons ,name ,func))))
		source))
	    (advice-add (quote,srcfn) :around (quote ,advfn)))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; * Text editing
;;; ** misc text editing packages
(use-package expand-region :ensure t :bind ("C-=" . er/expand-region))
(use-package shrink-whitespace :ensure t :bind ("M-SPC" . shrink-whitespace))
(use-package string-edit :ensure t)

(use-package iedit
  :ensure t
  ;; iedit-rectangle default C-RET is taken in org mode
  :bind (("C-;" . iedit-mode)
	 ("C-:" . iedit-rectangle-mode))
  )

;; wrap region mode
;; allows selecting a region and "wrapping" it with the defined
;; delimiters. E.g. typing "(" will wrap the region in parentheses.
(use-package wrap-region
  :ensure t
  :config (progn (wrap-region-add-wrappers
		  '(("=" "=")
		    ("/" "/")
		    ("+" "+")
		    ("*" "*")
		    ("$" "$")))
		 (mapc (lambda (mode)
			 (add-to-list 'wrap-region-except-modes mode))
		       '(magit-popup-mode
			 ibuffer-mode
			 mu4e-headers-mode
			 mu4e-view-mode))
		 (wrap-region-global-mode t))
  )

;;; ** Templates and Yasnippet

(use-package yasnippet
  :ensure t
  :demand t
  :mode ("/\\.emacs\\.d/snippets/" . snippet-mode)
  :config (progn
	    ;; turn on yasnippets mode globally and define a place for
	    ;; my own yas snippets
	    (setq my-yas-snippet-dir "~/.emacs.d/snippets/")
	    (unless (file-exists-p my-yas-snippet-dir)
	      (make-directory my-yas-snippet-dir))
	    (yas-load-directory my-yas-snippet-dir)
	    (yas-global-mode 1)
	    ;; terminal emulation modes do not work well with yasnippet
	    (defun disable-yas-minor-mode () (yas-minor-mode -1))
	    (add-hook 'term-mode-hook 'disable-yas-minor-mode)))
;; TODO: I may want to investigate yas-activate-extra-mode for
;; activating snippets in other (or even all) modes.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ** Indentation, whitespace and tabs

;; customize whitespace mode
;; refer to https://dougie.io/coding/tabs-in-emacs/

(defun dfeich-whitespace-prog-config ()
  (setq-local whitespace-style '(face trailing empty))
  (whitespace-mode))

(add-hook 'emacs-lisp-mode-hook 'dfeich-whitespace-prog-config)
(add-hook 'python-mode-hook 'dfeich-whitespace-prog-config)
(add-hook 'yaml-mode-hook 'dfeich-whitespace-prog-config)
(add-hook 'puppet-mode-hook 'dfeich-whitespace-prog-config)

;; aggressive indent mode - https://github.com/Malabarba/aggressive-indent-mode
(use-package aggressive-indent
  :ensure t
  :demand t
  :config (progn
	    (global-aggressive-indent-mode 1)
	    (dolist (mode '(html-mode web-mode))
	      (add-to-list 'aggressive-indent-excluded-modes mode))
	    ;; one can fine tune the indenting, e.g. for c++
	    ;; (add-to-list
	    ;;  'aggressive-indent-dont-indent-if
	    ;;  '(and (derived-mode-p 'c++-mode)
	    ;; 	   (null (string-match "\\([;{}]\\|\\b\\(if\\|for\\|while\\)\\b\\)"
	    ;; 			       (thing-at-point 'line)))))
	    ))

;; electric-indent-mode indents code automatically after a line is complete. It only
;; works from emacs 24.4 on. I disable it in favor of A. Malabarba's aggressive indent
;; (electric-indent-mode 1)

;; highlight-indent-guides is very useful for modes that rely on indentation
;; like python or yaml. It graphically highlights the indentation levels
;; https://github.com/DarthFennec/highlight-indent-guides
(use-package highlight-indent-guides
  :ensure t
  :config (setq highlight-indent-guides-method 'column
		highlight-indent-guides-responsive 'top)
  :hook ((python-mode yaml-mode) . highlight-indent-guides-mode))

;; an alternative for indentation highlighting: highlight-indentation mode
;; https://github.com/antonj/Highlight-Indentation-for-Emacs
;; Works only with space based indentation

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ** Smartparens and rainbow delimiters
;;  first we load the standard config that comes with smartparens
(use-package smartparens
  :ensure t
  :config (progn
	    (use-package smartparens-config)
	    (smartparens-global-mode 1)
	    ;; highlight matching parentheses
	    (show-smartparens-global-mode)

	    ;; do not pair single quote in org mode
	    (sp-local-pair 'org-mode "'" nil :actions nil)

	    (defun dfeich-disable-smartparens-mode ()
	      (smartparens-mode -1)
	      ;; since we still want to have matching parens highlighting, I set
	      (show-paren-mode))
	    ;; terminal emulation modes (e.g. ansi term) do not work well with
	    ;; yasnippet and autopair modes (term character mode returns errors)
	    (add-hook 'term-mode-hook 'dfeich-disable-smartparens-mode)
	    ;; in lisp mode I prefer paredit
	    (add-hook 'emacs-lisp-mode-hook 'dfeich-disable-smartparens-mode)
	    ;; web-mode has it's own parens matching
	    (add-hook 'web-mode-hook 'dfeich-disable-smartparens-mode)))


;; rainbow-delimiters
;; highlight delimiters using colors. Very useful for lisp
(use-package rainbow-delimiters
  :ensure t
  :config
  (add-hook 'emacs-lisp-mode-hook 'rainbow-delimiters-mode))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ** Spell checker
;; The default installation in Ubuntu does not work with the ispell
;; module that comes with emacs24 when trying to use other than the
;; default language. The configuration contains the wrong strings that
;; do not match the filenames (e.g. german8 instead of
;; de_DE). Currently I just use the override variable for providing
;; some correct definitions.  This is more correct than using
;; (add-to-list 'ispell-dictionary-alist ...)
(setq  ispell-base-dicts-override-alist
       '(("de_DE"
	  "[a-zA-ZäöüßÄÖÜ]" "[^a-zA-ZäöüßÄÖÜ]" "[']" t
	  ("-C" "-d" "de_DE")
	  "~latin1" iso-8859-1)
	 ("de_CH"
	  "[a-zA-ZäöüÄÖÜ]" "[^a-zA-ZäöüÄÖÜ]" "[']" t
	  ("-C" "-d" "de_CH")
	  "~latin1" iso-8859-1)
	 ))

;; a buffer local dictionary can be identified by either having the
;; ispell-dictionary-keyword ("Local IspellDict: ") in the header or
;; setting ispell-local-dictionary in a Local Variables definition at
;; the end of the file

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ** Code Syntax checker
(use-package flycheck :ensure t
  :config (progn
	    (use-package flycheck-package
	      :ensure t
	      :config (flycheck-package-setup))))

;;; * Load Org init file
;; we want the newest org mode with the contributed packages
(use-package org :ensure org-plus-contrib)
(load-file "~/.emacs.d/org-init.el")

;;; * Internet related
;;; ** auth - keeping secrets in a gpg encrypted file
(setq auth-sources '((:source "~/.authinfo.gpg")))
;; note that one can debug the auth functions with
;; (setq auth-source-debug t)
;; to forget all cached authentications, use
;; (auth-source-forget-all-cached)

;; adapted from https://github.com/jorgenschaefer/circe/wiki/Configuration
(defun dfeich-get-password-from-auth-source (&rest params)
  "Retrieve password from an auth-source.
`PARAMS' should be a number of :key value pairs use the standardized keywords
like :host, :user, :port"
  ;; NOTE: I did quite some debugging in order to find out why this does always
  ;; return the initial record
  ;;        (auth-source-search :machine "irc.freenode.net" :login "dfeich")
  ;; but this works
  ;;        (auth-source-search :host "irc.freenode.net" :user "dfeich")
  ;; reason is that `auth-source-netrc-normalize' maps the netrc keywords like
  ;; "machine" to the standardized ones like "host". The first query end up in
  ;; asking for fieldsthat do no exist in the structure, and then the first record
  ;; is returned (logic is that "nothing did not match"...)
  (require 'auth-source)
  (let ((match (car (apply 'auth-source-search params))))
    (if match
        (let ((secret (plist-get match :secret)))
          (if (functionp secret)
              (funcall secret)
            secret))
      (error "Password not found for %S" params))))

;;; ** eww - the Emacs web browser
(setq eww-search-prefix "http://www.google.ch/search?q=")
(defun eww-open-url-at-point (beg end)
  "Open URL or sexp at point in eww. If a region is selected, use that
string for a search in eww."
  (interactive (if (use-region-p)
		   (list (region-beginning) (region-end))
		 '(nil nil)))
  (let ((url (cond (beg
		    (buffer-substring beg end))
		   ((thing-at-point 'url))
		   (t (thing-at-point 'sexp)))))
    (if url
	(eww url)
      (message "Error: No URL or search expression at point"))))

;;; ** Chrome and Firefox integration
;; https://www.emacswiki.org/emacs/Edit_with_Emacs
;; development at https://github.com/stsquad/emacs_chrome
;; run (edit-server-start 4) to get debug output in buffer *edit-server-log*
(use-package edit-server
  :ensure t
  :config (when (daemonp)
	    (edit-server-start)))

;;; * MISC MAJOR MODES
;;; ** LaTeX
(setq latex-run-command "pdflatex")
;; note that a lot of latex related functionality for Org-mode is in the Org
;; mode configuration

;;; ** Man page mode (woman)
;; showing of man pages (woman)
;; (setq Man-notify-method 'newframe)
(defun dfeich-show-manpage (prefix)
  "Adapt the frame opening behavior helm-man-woman.  Open in a
new frame if current buffer is not already a man buffer."
  (interactive "P")
  (let ((Man-notify-method
	 (if (eq major-mode 'Man-mode)
	     'pushy
	   'newframe)))
    (funcall-interactively #'helm-man-woman prefix)))

(defun dfeich-Man-notify-when-ready (orig-fun &rest args)
  "If current window has man major mode, use other Man-notify-method."
  (let ((Man-notify-method
	 (if (eq major-mode 'Man-mode)
	     'aggressive
	   'newframe)))
    (message "major-mode: %s   buffer: %s" major-mode (buffer-name))
    (apply orig-fun args)))
(advice-add 'Man-getpage-in-background :around #'dfeich-Man-notify-when-ready)

;;; * Some minor mode configurations
;;; ** Folding

;; convenience functions (cycling) for outline-mode. Originally written by Carsten Dominik
(use-package outline-magic
  :ensure t
  :after outline
  :config (define-key outline-minor-mode-map (kbd "<C-tab>") 'outline-cycle))


;;; ** openwith for opening files in external applications
(use-package openwith
  :ensure t
  :config (progn
	    (openwith-mode t)
	    (setq openwith-associations
		  '(("\\.mp3\\'" "xmms" (file))
		    ("\\.\\(?:mpe?g\\|mp4\\|MP4\\|avi\\|wmv\\)\\'" "mplayer"
		     ("-idx" file))
		    ("\\.odp\\|\\.ods\\|\\.odt\\|\\.doc\\|\\.docx\\|\\.pptx\\|\\.ppt'" "libreoffice"
		     (file))))
	    ;; disabled ("\\.pdf\\'" "evince" (file))
	    ;;
	    ;; openwith creates some problem with certain functions,
	    ;; e.g. when using dired-mark-files-containing-regexp
	    ;; (because it needs to search in files and open them), it
	    ;; opens any pdf file found in the directory while marking
	    ;; the files. This function-advising is from
	    ;; https://gist.github.com/oantolin/1846eef35ec49c359b69
	    ;; It turns openwith off while running selected functions
	    (defun turn-off-openwith-mode (orig-fun &rest args)
	      "Ensure openwith-mode is off when running `orig-fun'"
	      (let ((openwith-mode-on? openwith-mode))
		(when openwith-mode-on? (openwith-mode -1))
		(apply orig-fun args)
		(when openwith-mode-on? (openwith-mode 1))))

	    (dolist (cmd '(dired-mark-files-containing-regexp
			   message-send-and-exit
			   dired-do-copy))
	      (advice-add cmd :around #'turn-off-openwith-mode))

	    ))

;;; ** git and version control structure
(use-package magit
  :ensure t
  :bind (("<f12> <f12>" . magit-status)
	 ("<f12> b" . magit-blame)
	 ("<f12> f" . magit-log-buffer-file)))

(use-package forge :ensure t
  :after magit
  :config (progn
	    (push '("git.psi.ch" "git.psi.ch/api/v4" "git.psi.ch"
		    forge-gitlab-repository)
		  forge-alist)
	    ;; TODO: put your github account here:
	    ;; (setq forge-owned-accounts '(("dfeich")))
	    ))

(use-package git-timemachine
  :ensure t
  :config (set-face-attribute 'git-timemachine-minibuffer-detail-face nil
			      :foreground "Firebrick")
  :bind ("<f12> t" . git-timemachine))

(use-package git-gutter
  :ensure t
  :commands git-gutter
  :bind ("<f12> g" . git-gutter-mode))

;; browse all files in a git repo
;; may require color (faces) adaption in helm-ls-git group
(use-package helm-ls-git
  :ensure t
  :bind ("<f12> l" . helm-browse-project))

;; links for org mode
;; to get correctly exported links pointing to the respective repo web pages
;; look at orgit-export-alist
(use-package orgit :ensure t
  :after org)

;;; ** searching and navigation

;; regexp defining the end of a sentence
(setq sentence-end "[.?;!][
]")

(use-package avy
  :ensure t
  :bind (("C-ö" . avy-goto-char-timer)
	 ("C-<" . avy-goto-char-timer)
	 ))

(use-package helm-swoop
  :ensure t
  :bind (( "<f5> s" . helm-swoop)
	 ( "<f5> S" . helm-multi-swoop)))


;; like isearch, but using python regexp syntax
(use-package visual-regexp :ensure t)
(use-package visual-regexp-steroids :ensure t
  :bind (("<f9> C-s" . vr/isearch-forward)
	 ("<f9> C-r" . vr/isearch-backward)))

;; wgrep - allows to write changes made to a grep buffer back to the files
;;    C-p  (in a grep mode buffer) enter wgrep mode
;;    C-C  write the changes to the buffers (but not yet to the files)
;;    C-ESC  undo all changes
;;    M-x wgrep-save-all-buffers   save all modified buffers to their files
(use-package wgrep :ensure t :defer t)
(use-package wgrep-helm :ensure t :defer t)

;;; ** dired add-ons

;; nice icons
(use-package all-the-icons :ensure t)
;; calling `all-the-icons-install-fonts' installed fonts
;; in ~/.local/share/fonts/
(use-package all-the-icons-dired :ensure t
  :config (add-hook 'dired-mode-hook 'all-the-icons-dired-mode))

;; allows narrowing based on a filter expression. I add this to a hydra
;; further below
(use-package dired-narrow
  :ensure t)

;;; ** miscellaneous minor mode configs

;; Package defining pdf-view-mode. Provides working with annotations
;; and "occur" style searching in PDF files.
(use-package pdf-tools
  :ensure t
  :config (pdf-tools-install))

;; extended image manipulation - uses the mogrify utility from imagemagick
;; TODO: check whether eimp is needed
;; (use-package eimp :ensure t)


(use-package graphviz-dot-mode
  :ensure t
  :mode ("\\.dot$" . graphviz-dot-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; * Programming
;;; ** general

;; use lsp-mode from https://github.com/emacs-lsp/lsp-mode
(use-package lsp-mode :ensure t
  :hook ((python-mode c-mode) . lsp-deferred)
  :config (progn
	    (setq lsp-prefer-flymake nil
		  ;; non-standard clangd V8 installation on ubuntu
		  lsp-clients-clangd-executable "clangd-8"))
  :commands lsp lsp-deferred)

(use-package company-lsp :ensure t
  :commands company-lsp)

(use-package lsp-ui :ensure t
  :hook (lsp . lsp-ui)
  :commands lsp-ui-mode
  :config (setq lsp-ui-doc-delay 0.5))

;;; ** PYTHON
;;
;; Note that the original jedi package only works with auto-complete, and not
;; with company-mode
;; python completion through jedi
;; (setq jedi:setup-keys t)

(use-package python
  :config (progn
	    ;; show line numbers on the left for python using the new (26.1) mode
	    (display-line-numbers-mode)
	    ;; load my own python helper functions
	    (load-file (concat dfeich-site-lisp "/my-pydoc-helper.el"))

	    (when (featurep 'flycheck)
	      (add-hook 'python-mode-hook 'flycheck-mode))

	    ;; Jupyter integration for emacs
	    ;; note that it may conflict with ob-ipython
	    (use-package jupyter :ensure t)

	    (use-package cython-mode :ensure t)

	    ;; Ipython v5 introduced a new terminal interface that is no longer
	    ;; compatible with emacs inferior-shell
	    ;; http://ipython.readthedocs.io/en/stable/whatsnew/version5.html#id1
	    ;; therefore needs --simple-prompt
	    (setq python-shell-interpreter "ipython"
		  python-shell-interpreter-args "-i --simple-prompt"))
  :bind (:map python-mode-map
	      ("<M-right>" . python-indent-shift-right)
	      ("<M-left>" . python-indent-shift-left))
  )

;; integration with anaconda based conda environments
;; (use-package conda
;;   :config (setq conda-anaconda-home "/opt/anaconda/python3.6"
;;                 conda-env-home-directory "/opt/anaconda"
;;                 conda-env-subdirectory "my-conda-envs"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ** EMACS lisp and lisp mode settings
;;

;; TODO: find correct way of having M-q put two spaces at sentence
;; ends for following emacs lisp convention
;; (defun dfeich-emacs-lisp-mode-settings ()
;;   (set (make-local-variable 'colon-double-space) t)
;;   (set (make-local-variable 'sentence-end-double-space) t))

;; (add-hook 'emacs-lisp-mode-hook 'dfeich-emacs-lisp-mode-settings)

;; Paredit mode for writing lisp
;; very nice tutorial: http://danmidwood.com/content/2014/11/21/animated-paredit.html
(use-package paredit
  :ensure t
  :config (progn (add-hook 'emacs-lisp-mode-hook 'paredit-mode)
		 (add-hook 'lisp-interaction-mode-hook 'paredit-mode)
		 ;; in scratch buffer I would like to have the C-j result echoing
		 (defun dfeich-paredit-eval-or-newline ()
		   (interactive)
		   (if (eq major-mode 'lisp-interaction-mode)
		       (eval-print-last-sexp)
		     (paredit-newline)))
		 (bind-key "C-j" #'dfeich-paredit-eval-or-newline
			   paredit-mode-map))
  )

(use-package s :ensure t)

;; A modern list api for Emacs
(use-package dash :ensure t)

;; inline expansion of lisp macros
(use-package macrostep :ensure t :defer t)

;; provides nicer help pages for lisp command with additional information
(use-package helpful :ensure t
  :config (eval-after-load 'helm-elisp
	    (progn
	      ;; note: there seems to be a general problem with
	      ;; helpful-command. It has some keymap error
	      (dfeich-helm-add-action-to-sourcefn helm-def-source--emacs-commands
						  "helpful-command"
						  (lambda (sel)
						    (funcall-interactively 'helpful-command (intern sel))))

	      (dfeich-helm-add-action-to-sourcefn helm-def-source--emacs-functions
						  "helpful-function"
						  (lambda (sel)
						    (funcall-interactively 'helpful-function (intern sel))))

	      (dfeich-helm-add-action-to-sourcefn helm-def-source--emacs-variables
						  "helpful-variable"
						  (lambda (sel)
						    (funcall-interactively 'helpful-variable (intern sel)))))))
;; I put here some comments to undefine the advices from above
;; (dfeich-advice-unadvice 'helm-def-source--emacs-commands)
;; (dfeich-advice-unadvice 'helm-def-source--emacs-functions)
;; (dfeich-advice-unadvice 'helm-def-source--emacs-variables)

;; eldoc-eval provides function help when using eval-expression (M-:)
(use-package eldoc-eval :ensure t
  :config (progn
	    (eldoc-in-minibuffer-mode)
	    ;; there is a problem using #'tooltip-show as a function
	    ;;(setq eldoc-in-minibuffer-show-fn #'tooltip-show)
	    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ** realgud debugger
;; note that the realgud-populate-common-fn-keys-function variable
;; only takes effect if realgud is fixed in key.el. I submitted a
;; bug here: https://github.com/realgud/realgud/issues/129
(use-package realgud
  ;; :load-path "~/.emacs.d/external/realgud"
  :ensure t
  :init (setq realgud-populate-common-fn-keys-function nil)
  :commands realgud:pdb realgud:bashdb realgud:ipdb)


;;; ** misc smaller programming modes

(use-package puppet-mode
  :ensure t
  :mode ("\\.pp$" . puppet-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; * KEY MAPPINGS AND HYDRAS
;;; ** Hydras
;;; *** context launcher for hydras
(defun dfeich-context-hydra-launcher ()
  "A launcher for hydras based on the current context."
  (interactive)
  (cl-case major-mode
    ('org-mode (let* ((elem (org-element-context))
		      (etype (car elem))
		      (type (org-element-property :type elem)))
		 (cl-case etype
		   (src-block (hydra-babel-helper/body))
		   (link (hydra-org-link-helper/body))
		   ((table-row table-cell) (hydra-org-table-helper/body) )
		   (t (message "No specific hydra for %s/%s" etype type)
		      (hydra-org-default/body))))
	       )
    ('bibtex-mode (org-ref-bibtex-hydra/body))
    ('ibuffer-mode (hydra-ibuffer-main/body))
    ('dired-mode (dired-helper/body))
    (t (message "No hydra for this major mode: %s" major-mode))))

(global-set-key (kbd "<f9> <f9>") 'dfeich-context-hydra-launcher)

;;; *** org mode hydras
(defhydra hydra-org-default (:color pink :hint nil)
  "
Org default hydra

_l_ insert template from last src block
_r_ insert src block ref with helm

_q_ quit
"
  ("l" dfeich-copy-last-src-block-head :color blue)
  ("r" helm-lib-babel-insert :color blue)
  ("q" nil :color blue))


(defhydra hydra-org-link-helper (:color pink :hint nil)
  "
org link helper
_i_ backward slurp     _o_ forward slurp    _n_ next link
_j_ backward barf      _k_ forward barf     _p_ previous link
_t_ terminal at path

_q_ quit
"
  ("i" org-link-edit-backward-slurp)
  ("o" org-link-edit-forward-slurp)
  ("j" org-link-edit-backward-barf)
  ("k" org-link-edit-forward-barf)
  ("n" org-next-link)
  ("p" org-previous-link)
  ("t" dfeich-gnome-terminal-at-link :color blue)
  ("q" nil :color blue))

(defhydra hydra-org-table-helper (:color pink :hint nil)
  "
org table helper
_r_ recalculate     _w_ wrap region      _c_ toggle coordinates
_i_ iterate table   _t_ transpose        _D_ toggle debugger
_B_ iterate buffer  _E_ export table     _n_ remove number separators
_e_ eval formula    _s_ sort lines       _d_ edit field

_q_ quit
"
  ("E" org-table-export :color blue)
  ("s" org-table-sort-lines)
  ("d" org-table-edit-field)
  ("e" org-table-eval-formula)
  ("r" org-table-recalculate)
  ("i" org-table-iterate)
  ("B" org-table-iterate-buffer-tables)
  ("w" org-table-wrap-region)
  ("D" org-table-toggle-formula-debugger)
  ("t" org-table-transpose-table-at-point)
  ("n" dfeich-org-table-remove-num-sep :color blue)
  ("c" org-table-toggle-coordinate-overlays :color blue)
  ("q" nil :color blue))

(defhydra hydra-babel-helper (:color pink :hint nil)
  "
org babel src block helper functions
_n_ next       _i_ info           _I_ insert header
_p_ prev       _c_ check
_h_ goto head  _E_ expand         _R_ insert src block ref
^ ^            _s_ split
_q_ quit       _r_ remove result  _e_ examplify region

"
  ("i" org-babel-view-src-block-info)
  ("I" org-babel-insert-header-arg)
  ("c" org-babel-check-src-block :color blue)
  ("s" org-babel-demarcate-block :color blue)
  ("n" org-babel-next-src-block)
  ("p" org-babel-previous-src-block)
  ("E" org-babel-expand-src-block :color blue)
  ("e" org-babel-examplify-region :color blue)
  ("r" org-babel-remove-result :color blue)
  ("h" org-babel-goto-src-block-head)
  ("R" helm-lib-babel-insert :color blue)
  ("q" nil :color blue))
(global-set-key (kbd "<f9> b") 'hydra-babel-helper/body)


;;; *** window management hydra
(defun shrink-frame-horizontally (&optional increment)
  (interactive "p")
  (let ((frame (window-frame)))
    (set-frame-width frame (- (frame-width frame) increment))))
(defun enlarge-frame-horizontally (&optional increment)
  (interactive "p")
  (let ((frame (window-frame)))
    (set-frame-width frame (+ (frame-width frame) increment))))
(defun shrink-frame-vertically (&optional increment)
  (interactive "p")
  (let ((frame (window-frame)))
    (set-frame-height frame (- (frame-height frame) increment))))
(defun enlarge-frame-vertically (&optional increment)
  (interactive "p")
  (let ((frame (window-frame)))
    (set-frame-height frame (+ (frame-height frame) increment))))

(defun shift-frame-right (&optional increment)
  (interactive "P")
  (unless increment (setq increment 20))
  (set-frame-parameter nil 'left (+ (frame-parameter nil 'left) increment)))
(defun shift-frame-left (&optional increment)
  (interactive "P")
  (unless increment (setq increment 20))
  (message "user-pos:" (frame-parameter nil 'user-position))
  (set-frame-parameter nil 'left (- (frame-parameter nil 'left) increment)))
(defun shift-frame-up (&optional increment)
  (interactive "P")
  (unless increment (setq increment 20))
  (set-frame-parameter nil 'top (- (frame-parameter nil 'top) increment)))
(defun shift-frame-down (&optional increment)
  (interactive "P")
  (unless increment (setq increment 20))
  (set-frame-parameter nil 'top (+ (frame-parameter nil 'top) increment)))

(defhydra hydra-window-mngm (:color pink :hint nil)
  "
frame    ^ ^ _m_ ^ ^    frame   ^ ^ _z_ ^ ^    window   ^ ^ _w_
sizing:  _j_ ^ ^ _k_    moving: _g_ ^ ^ _h_    sizing:  _a_ ^ ^ _s_
         ^ ^ _i_ ^ ^            ^ ^ _b_ ^ ^             ^ ^ _y_
"
  ("a" shrink-window-horizontally)
  ("s" enlarge-window-horizontally)
  ("y" enlarge-window)
  ("w" shrink-window)
  ("j" shrink-frame-horizontally)
  ("k" enlarge-frame-horizontally)
  ("i" shrink-frame-vertically)
  ("m" enlarge-frame-vertically)
  ("g" shift-frame-left)
  ("h" shift-frame-right)
  ("z" shift-frame-up)
  ("b" shift-frame-down)
  ("t" dfeich-toggle-window-split "toggle windows splitting")
  ("n" dfeich-open-buffer-in-new-frame "open buffer in new frame" :color blue)
  ("q" nil "quit" :color blue))

(global-set-key (kbd "C-c w") 'hydra-window-mngm/body)

;;; *** ibuffer hydra
;; from https://github.com/abo-abo/hydra/wiki/Ibuffer
(defhydra hydra-ibuffer-main (:color pink :hint nil)
  "
 ^Navigation^ | ^Mark^        | ^Actions^        | ^View^
-^----------^-+-^----^--------+-^-------^--------+-^----^-------
  _k_:    ʌ   | _m_: mark     | _D_: delete      | _g_: refresh
 _RET_: visit | _u_: unmark   | _S_: save        | _s_: sort
  _j_:    v   | _*_: specific | _a_: all actions | _/_: filter
-^----------^-+-^----^--------+-^-------^--------+-^----^-------
"
  ("j" ibuffer-forward-line)
  ("RET" ibuffer-visit-buffer :color blue)
  ("k" ibuffer-backward-line)

  ("m" ibuffer-mark-forward)
  ("u" ibuffer-unmark-forward)
  ("*" hydra-ibuffer-mark/body :color blue)

  ("D" ibuffer-do-delete)
  ("S" ibuffer-do-save)
  ("a" hydra-ibuffer-action/body :color blue)

  ("g" ibuffer-update)
  ("s" hydra-ibuffer-sort/body :color blue)
  ("/" hydra-ibuffer-filter/body :color blue)

  ("o" ibuffer-visit-buffer-other-window "other window" :color blue)
  ("q" ibuffer-quit "quit ibuffer" :color blue)
  ("." nil "toggle hydra" :color blue))

(defhydra hydra-ibuffer-mark (:color teal :columns 5
				     :after-exit (hydra-ibuffer-main/body))
  "Mark"
  ("*" ibuffer-unmark-all "unmark all")
  ("M" ibuffer-mark-by-mode "mode")
  ("m" ibuffer-mark-modified-buffers "modified")
  ("u" ibuffer-mark-unsaved-buffers "unsaved")
  ("s" ibuffer-mark-special-buffers "special")
  ("r" ibuffer-mark-read-only-buffers "read-only")
  ("/" ibuffer-mark-dired-buffers "dired")
  ("e" ibuffer-mark-dissociated-buffers "dissociated")
  ("h" ibuffer-mark-help-buffers "help")
  ("z" ibuffer-mark-compressed-file-buffers "compressed")
  ("b" hydra-ibuffer-main/body "back" :color blue))

(defhydra hydra-ibuffer-action (:color teal :columns 4
				       :after-exit
				       (if (eq major-mode 'ibuffer-mode)
					   (hydra-ibuffer-main/body)))
  "Action"
  ("A" ibuffer-do-view "view")
  ("E" ibuffer-do-eval "eval")
  ("F" ibuffer-do-shell-command-file "shell-command-file")
  ("I" ibuffer-do-query-replace-regexp "query-replace-regexp")
  ("H" ibuffer-do-view-other-frame "view-other-frame")
  ("N" ibuffer-do-shell-command-pipe-replace "shell-cmd-pipe-replace")
  ("M" ibuffer-do-toggle-modified "toggle-modified")
  ("O" ibuffer-do-occur "occur")
  ("P" ibuffer-do-print "print")
  ("Q" ibuffer-do-query-replace "query-replace")
  ("R" ibuffer-do-rename-uniquely "rename-uniquely")
  ("T" ibuffer-do-toggle-read-only "toggle-read-only")
  ("U" ibuffer-do-replace-regexp "replace-regexp")
  ("V" ibuffer-do-revert "revert")
  ("W" ibuffer-do-view-and-eval "view-and-eval")
  ("X" ibuffer-do-shell-command-pipe "shell-command-pipe")
  ("b" nil "back"))

(defhydra hydra-ibuffer-sort (:color amaranth :columns 3)
  "Sort"
  ("i" ibuffer-invert-sorting "invert")
  ("a" ibuffer-do-sort-by-alphabetic "alphabetic")
  ("v" ibuffer-do-sort-by-recency "recently used")
  ("s" ibuffer-do-sort-by-size "size")
  ("f" ibuffer-do-sort-by-filename/process "filename")
  ("m" ibuffer-do-sort-by-major-mode "mode")
  ("b" hydra-ibuffer-main/body "back" :color blue))

(defhydra hydra-ibuffer-filter (:color amaranth :columns 4)
  "Filter"
  ("m" ibuffer-filter-by-used-mode "mode")
  ("M" ibuffer-filter-by-derived-mode "derived mode")
  ("n" ibuffer-filter-by-name "name")
  ("c" ibuffer-filter-by-content "content")
  ("e" ibuffer-filter-by-predicate "predicate")
  ("f" ibuffer-filter-by-filename "filename")
  (">" ibuffer-filter-by-size-gt "size")
  ("<" ibuffer-filter-by-size-lt "size")
  ("/" ibuffer-filter-disable "disable")
  ("b" hydra-ibuffer-main/body "back" :color blue))

(define-key ibuffer-mode-map "." 'hydra-ibuffer-main/body)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; *** dired hydra

(defhydra dired-helper (:color blue :hint nil)
  "
 _n_: narrow
 _r_: narrow regexp
 _f_: narrow fuzzy
"
  ("n" dired-narrow)
  ("r" dired-narrow-regexp)
  ("f" dired-narrow-fuzzy))

;;; *** misc hydras
;; an analog of the earlier toggle map I used

;; from a Gist by Michael Fogleman
;; https://gist.github.com/mwfogleman/95cc60c87a9323876c6c
;; even though I am pretty comfortable with the C-x n n / C-x n w
;; default keys settings
(defun narrow-or-widen-dwim (p)
  "If the buffer is narrowed, it widens. Otherwise, it narrows intelligently.
Intelligently means: region, subtree, or defun, whichever applies
first.

With prefix P, don't widen, just narrow even if buffer is already
narrowed."
  (interactive "P")
  (declare (interactive-only))
  (cond ((and (buffer-narrowed-p) (not p)) (widen))
        ((region-active-p)
         (narrow-to-region (region-beginning) (region-end)))
        ((derived-mode-p 'org-mode) (org-narrow-to-subtree))
        (t (narrow-to-defun))))
;; (define-key my-toggle-map "n" 'narrow-or-widen-dwim)

(autoload 'dired-toggle-read-only "dired" nil t)

(defhydra hydra-toggle-map (:color blue)
  "toggle map"
  ("c" column-number-mode "colnum")
  ("d" toggle-debug-on-error "debug-on-error")
  ("f" auto-fill-mode "auto fill")
  ("l" toggle-truncate-lines "truncate-lines")
  ("q" toggle-debug-on-quit "debug on quit")
  ("r" dired-toggle-read-only "read-only")
  ("n" narrow-or-widen-dwim "narrow/widen")
  )
(global-set-key (kbd "C-x t") 'hydra-toggle-map/body)

;;; ** GLOBAL KEY MAPPINGS
;; These intentionally are kept at the end

;; easy moving to other windows in the same frame
(global-set-key (kbd "C-c <left>") 'windmove-left)
(global-set-key (kbd "C-c <right>") 'windmove-right)
(global-set-key (kbd "C-c <up>") 'windmove-up)
(global-set-key (kbd "C-c <down>") 'windmove-down)

;; The most important org mode commands that need to be available globally
(global-set-key (kbd "C-c a") 'org-agenda)
(global-set-key (kbd "C-c c") 'org-capture)
(global-set-key (kbd "C-c l") 'org-store-link)


(use-package discover-my-major :bind ("\C-hj" . discover-my-major))
(use-package helm-descbinds
  :ensure t
  :bind ( "<f5> d" . helm-descbinds))

(global-set-key (kbd "<f6> f") 'make-frame)
(global-set-key (kbd "<f6> p") 'proced)
(global-set-key (kbd "<f6> <f6> k") 'save-buffers-kill-emacs)


(global-set-key (kbd "<f12> a") 'vc-annotate)

(global-set-key (kbd "C-x C-b") 'ibuffer-list-buffers)
(global-set-key (kbd "M-c") 'calc-dispatch)
;; why am I getting problems with max-lisp-eval-depth here:
;;(global-set-key (kbd "C-$") 'yas-expand)

(global-set-key (kbd "M-j") 'my-join-region-or-line)
(global-set-key (kbd "<s-left>") 'backward-sexp)
(global-set-key (kbd "<s-right>") 'forward-sexp)

(global-set-key (kbd "C-c O") 'eww-open-url-at-point)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; * Footer
;; We activate folding using outline-mode for this buffer
;; Local Variables:
;; eval: (outline-minor-mode)
;; outline-regexp: ";;; \\\*+"
;; outline-promotion-headings: (";;; *" ";;; **" ";;; ***" ";;; ****")
;; End:
