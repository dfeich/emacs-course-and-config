;;; * ORG mode basic configuration

;; activate the single letter speed commands when cursor is at the beginning
;; of a headline, e.g. t for setting a todo, u for going up, ...
(setq org-use-speed-commands t)

;; define whether to use globally unique IDs for links, i.e. whether the link
;; will point to a unique-ID property of an org headline.
;; For the moment I choose:  Use existing ID, do not create one (so the ID will
;; be used when the org headline has such a property, and else not).
(setq org-id-link-to-org-use-id 'use-existing)

;; allow expansion of structure-templates listed in `org-insert-structure-template'
;; e.g. by typing <e+TAB for expending to an example block. This is considered
;; a bit anachronistic, and current best practices suggest to use C-c C-, to insert
;; a block
(require 'org-tempo)

;; turn on org-table minor mode for all other text modes
(setq dfeich/orgtbl-exclude-modes '(org-mode yaml-mode))
(defun turn-on-orgtbl-conditionally ()
  (unless (member 'org-mode dfeich/orgtbl-exclude-modes)
    (turn-on-orgtbl))
  )
(add-hook 'text-mode-hook 'turn-on-orgtbl-conditionally)

;;; * org agenda
;;; ** basic configuration
;; default directory to look for org files
(setq org-directory "~/Documents/orgcourse/agenda/")
(setq org-agenda-files (list (concat org-directory "course01-basics.org")
			     (concat org-directory "tasks.org")))

;; 'q' key should only bury agenda buffer, not delete it
(setq org-agenda-sticky t)

;; turn on log view by default
(setq org-agenda-start-with-log-mode t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ** clocking and time reporting and options for TODO item state changes
(setq org-log-done 'time)
;; this would also prompt for a comment when closing a TODO
					;  (setq org-log-done 'note)

;; save clock times and state messages into a drawer called "LOGBOOK"
(setq org-log-into-drawer t)

;; To save the clock history and active clock across emacs sessions
(setq org-clock-persist t)
(org-clock-persistence-insinuate)

;; org-duration-format for setting the format in clocktables and elsewhere
(setq org-duration-format 'h:mm)

;; my own local clocking convenience library
(use-package org-clock-convenience
  :ensure t
  :bind (:map org-agenda-mode-map
	      ("<S-up>" . org-clock-convenience-timestamp-up)
	      ("<S-down>" . org-clock-convenience-timestamp-down)
	      (";" . org-clock-convenience-fill-gap)
	      ("'" . org-clock-convenience-fill-gap-both)
	      ("<C-down>" . org-clock-convenience-forward-log-line)
	      ("<C-up>" . org-clock-convenience-backward-log-line)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ** Holidays calendar definitions
(setq general-holidays nil)
(setq hebrew-holidays nil)
(setq islamic-holidays nil)
;; Swiss national holidays
(setq dfeich-holiday-other-holidays 
      '((holiday-fixed 1 1 "Neujahr")
        (holiday-fixed 1 2 "Berchtoldstag")
        (holiday-easter-etc -2 "Karfreitag")
        (holiday-easter-etc 1 "Ostermontag")
        (holiday-easter-etc 39 "Auffahrt")
        (holiday-easter-etc 50 "Pfingstmontag")
	(holiday-easter-etc 60 "Fronleichnam")
	(holiday-fixed 8 15 "Mariae Himmelfahrt")
        (holiday-fixed 11 1 "Allerheiligen")
        (holiday-fixed 5 1   "Tag der Arbeit") 
        (holiday-fixed 8 1  "Nationalfeiertag") 
        (holiday-fixed 12 25 "Weihnachten")
        (holiday-fixed 12 26 "Stephanstag")))

(setq calendar-holidays (append holiday-christian-holidays
				holiday-solar-holidays
				dfeich-holiday-other-holidays))

;;; ** configuration for refiling entries
;; Targets include this file and any file contributing to the agenda
;; - up to 9 levels deep
(setq org-refile-targets (quote ((nil :maxlevel . 9)
                                 (org-agenda-files :maxlevel . 9))))

;; since we use IDO with fuzzy matching, we choose to prompt for
;; completion of target paths in steps
(setq org-refile-use-outline-path t)

(setq org-outline-path-complete-in-steps nil)

;;; ** agenda view definitions
;; my custom agenda views
(setq org-agenda-custom-commands
      '(("n" "Agenda and all TODO's" ((agenda "") (alltodo)))
	("w" "Agenda and waiting tasks"
	 ( (agenda "" ((org-agenda-span 1) (org-agenda-show-log t)))
	   (todo "WAIT") (todo "WAITFM")
	   (todo "TODO" ((org-agenda-skip-function
			  '(org-agenda-skip-entry-if 'scheduled 'deadline))
			 (org-agenda-overriding-header
			  "unscheduled TODOs without a deadline:")
			 ))))
	("h" . "my custom searches")
	("hd" todo "DONE" )
	("ha" todo-tree "DONE")
	("hw" "waiting tasks" todo "WAIT")
	("hc" tags "CLOSED<=\"<-4w>\"")
	("hm" tags-todo "+mbo")
	("hu" "unscheduled and no deadline" todo "TODO"
	 ((org-agenda-skip-function
	   '(org-agenda-skip-entry-if 'scheduled 'deadline))
	  (org-agenda-overriding-header "unscheduled TODOs without a deadline:")))))

;; include the diary in the agenda view
(setq diary-file (concat org-directory "diary"))
(setq org-agenda-include-diary t)

;; very nice grouping view using alphapapa's org-super-agenda
(use-package org-super-agenda
  :ensure t
  :config (progn (org-super-agenda-mode)
		 (setq  org-super-agenda-groups
			'((:name "Schedule"
				 :time-grid t)
			  (:name "Captured - to be moved"
				 :tag "captured")
			  (:auto-group t)
			  (:name "Emacs Course"
				 :tag "emacs_course")))))


;;; * Org capture templates
;; q.v. the org manual: Capture templates and template expansion
;; region selected text will be inserted at %i
(setq my-capture-task-loc
      (list 'file+headline (concat org-directory "tasks.org")
	    "Captured Tasks"))
(setq org-capture-templates
      `(("m" "Mail capture" entry ,my-capture-task-loc
	 ,(concat "* TODO %?Mail by %:fromname: %:subject\n"
		  "SCHEDULED: %t\n"
		  "  :LOGBOOK:\n"
		  "  - State \"TODO\"       from \"\"           %U\n"
		  "  :END:\n"
		  "  - %:date Mail from %:fromname %a"))
	("M" "Milestone" entry ,my-capture-task-loc
	 ,(concat "* MSTONE %?\n"
		  "  :LOGBOOK:\n"
		  "  - State \"MSTONE\"       from \"\"           %U\n"
		  "  :END:\n"
		  "  - defined in %a\n"
		  ))
	("t" "todo" entry ,my-capture-task-loc
	 ,(concat "* TODO %?\n"
		  "SCHEDULED: %t\n"
		  "  :LOGBOOK:\n"
		  "  - State \"TODO\"       from \"\"           %U\n"
		  "  :END:\n"
		  "  - reference from %f: %a"))
        ("j" "Journal" entry (file+datetree ,(concat org-directory
						     "journal.org"))
	 "* %?\nEntered on %U\n  %i\n")
	("J" "Journal + Link" entry (file+datetree ,(concat org-directory
							    "journal.org"))
	 "* %?\nEntered on %U\n  %i\n  %a")
	))

;;; * linking to external applications

;; Thunderbird mail - open thunderlinks in thunderbird
;; You need to get the thunderlink extension to use that
;; https://addons.thunderbird.net/en-US/thunderbird/addon/thunderlink/
(defun org-thunderlink-open (path)
  "open thunderlink"
  (shell-command
   (format "thunderbird -thunderlink thunderlink:%s" path)))

(defun org-thunderlink-export (path desc format)
  "export function for thunderlinks"
  (pcase format
    ("html" (concat "<u>" desc " (thunderlink)</u>"))
    (default desc)))

(org-add-link-type "thunderlink" #'org-thunderlink-open
		   #'org-thunderlink-export)

;; we define man page links like man:fstat(2) man:/usr/share/man/man2/fstat.2.gz
(defun org-man-link-open (lnk)
  (man (replace-regexp-in-string "^man:" "" lnk))
  )
(org-add-link-type "man" 'org-man-link-open)

;;; * Org exporter additions
;;; ** LaTeX exporter additions
(eval-after-load "ox-latex"
  '(progn 
     ;; we want source code blocks to be syntax colored when exporting
     ;; via latex.  We configure latex minted which uses python
     ;; pygments
     (add-to-list 'org-latex-packages-alist '("" "minted"))
     (setq org-latex-listings 'minted)
     ;; define mappings of src code language to lexer that minted shall use
     ;;(add-to-list 'org-latex-listings-langs '(ipython "Python"))
     (add-to-list 'org-latex-minted-langs '(ipython "python"))

     ;; note: the command should be executed 3 times to resolve
     ;; references.  The --synctex=1 option creates *.synctex.gz files
     ;; which can be used by a viewer to jump to the respective text
     ;; in the Tex file.
     (setq org-latex-pdf-process
	   (let
	       ((cmd (concat "pdflatex -shell-escape -interaction nonstopmode"
			     " --synctex=1"
			     " -output-directory %o %f")))
	     (list cmd
		   "cd %o; if test -r %b.idx; then makeindex %b.idx; fi"
		   "cd %o; bibtex %b"
		   cmd
		   cmd)))

     ;; document class for CVs. Originally I wanted to use moderncv,
     ;; but there was a clash with the hyperref
     ;; configuration. Something to look at later.
     (add-to-list 'org-latex-classes '("cv"
				       "\\documentclass[11pt]{article}"
				       ("\\section{%s}" . "\\section*{%s}")))

     ;; https://tex.stackexchange.com/questions/386620/export-into-pdf-a-moderncv-org-mode-file-mactex
     ;; you may need to switch of the hyperref package by setting it
     ;; to nil in org-latex-default-packages-alist
     (add-to-list 'org-latex-classes
		  '("moderncv"
		    "\\documentclass{moderncv}"
		    ("\\section{%s}" . "\\section*{%s}")
		    ("\\subsection{%s}" . "\\subsection*{%s}")))

     ;; I include gif images as one of the allowed formats. This also
     ;; requires the definition of a conversion rule for gif images in
     ;; the latex source code (using epstopdfDeclareGraphicsRule) which
     ;; requires the latex epstopdf package. Pdflatex must be allowed
     ;; to use -shell-escape for it to work.
     (setq org-latex-inline-image-rules
	   '(("file" . "\\.\\(pdf\\|jpeg\\|jpg\\|png\\|ps\\|eps\\|tikz\\|pgf\\|svg\\|gif\\)\\'")))
     ))

;; must be loaded in order to correctly enable bibliography functionality
;; from org-plus-contrib
(use-package ox-bibtex)

;; koma-letter is a special exporter mode for generating nice letter documents
;; from org-plus-contrib
(use-package ox-koma-letter)

;; for viewing LaTeX snippets in org mode, the imagemagick
;; method is recommended, because it does not cause problems
;; with the minted package
;; 2019-08-25: A security update to imagemagick required that I edited
;; /etc/ImageMagick-6/policy.xml to allow PDF read/write
;;     <policy domain="coder" rights="read|write" pattern="PDF" />
(setq org-preview-latex-default-process 'imagemagick)

;; this sets the scaling factor for the latex snippet images
(setq org-format-latex-options (plist-put org-format-latex-options :scale 2.0))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ** HTML exporter additions

;; We use mathtoweb for converting LaTeX equations to mathml
(setq org-latex-to-mathml-convert-command
      "java -jar %j -unicode -force -df %o %I"
      org-latex-to-mathml-jar-file
      "~/.emacs.d/javalib/mathtoweb.jar")

;; fontify source code that is exported to HTML
(use-package htmlize :ensure t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ** misc exporter additions

;; this package provides an exporter for github style markdown, provides
;; `org-gfm-export-to-markdown', etc.
(use-package ox-gfm :ensure t)

;; an exporter for the ugly JIRA markup
(use-package ox-jira :ensure t)

;;; * ORG-BABEL
;;; ** babel language configuration and settings

(use-package jupyter :ensure t)

;; define the active languages (this will trigger loading of the
;; respective modules)
(org-babel-do-load-languages 'org-babel-load-languages 
			     '((plantuml . t)
			       (dot . t)
			       (ditaa . t)
			       (emacs-lisp . t)
			       (python . t)
			       (sqlite . t)
			       (shell . t)
			       (sql .t)
			       (calc . t)
			       (gnuplot . t)
			       (C . t)
			       (jupyter . t) ;jupyter should be loaded last
			       ))

;; currently org has fundamental mode configured for graphviz/dot. I want to
;; have the correct mode configured in the alist
(setcdr (assoc "dot" org-src-lang-modes) 'graphviz-dot)

;; plantuml.jar from http://plantuml.sourceforge.net
;; http://eschulte.me/babel-dev/DONE-integrate-plantuml-support.html
(setq org-plantuml-jar-path "~/.emacs.d/javalib/plantuml.jar")

;; ditaa.jar from org installation package (in contrib/scripts)
(setq org-ditaa-jar-path "~/.emacs.d/javalib/ditaa/ditaa.jar")

;;; ** basic babel source block configuration
;; do syntax highlighting of src code blocks inside of an org buffer
(setq org-src-fontify-natively t)

;; treat typing tab in a src block as if it had been typed in the
;; native major mode of the language
(setq org-src-tab-acts-natively t)

;; preserve the indentation of the source blocks. Setting this to t
;; would result in the exported/editable code being indented exactly
;; as in the buffer. So, the indentation of the surrounding org mode
;; structure is ignored. While this may be helpful for some languages,
;; it destroys the readability of the org file.
(setq org-src-preserve-indentation nil)

;; additional indentation of the code in the source block relative to
;; the block's BEGIN/END
(setq org-edit-src-content-indentation 2)

;;; * Org keymap additions

;; In emacs 24.4 the `newline' command was changed, so that it no
;; longer indents when called non-interactively. In org, the return
;; key is mapped in a way that newline is called only through
;; org-return. This key setting fixes indentation by explicitely
;; calling org-return with an argument to enforce indentation.
(defun my-fix-org-return ()
  (interactive)
  (org-return t))

(defun my-org-hook-additions ()
  (define-key org-mode-map (kbd "<return>") 'my-fix-org-return))
(add-hook 'org-mode-hook 'my-org-hook-additions)

;;; * Org add ons
;; helm integration for org agenda
(use-package helm-org
  :ensure t
  :config
  (setq helm-org-format-outline-path t   ;; use item's whole outline path for candidates
	helm-org-show-filename nil ;; show agenda file's name in candidates
	helm-org-headings-max-depth 5 ;; maximum depth of a heading to be taken as a candidate
	))

;; my own package for screenshot integration
;; depending on your OS and screenshot utility, you may need to adapt
;; the screenshot command.
(use-package org-attach-screenshot
  :ensure t
  :bind ("<f6> s" . org-attach-screenshot)
  :config (setq org-attach-screenshot-dirfunction
		(lambda () 
		  (progn (assert (buffer-file-name))
			 (concat (file-name-sans-extension (buffer-file-name))
				 "-att")))
		org-attach-screenshot-command-line "gnome-screenshot -a -f %f"))
;;; * Footer
;; Local Variables:
;; eval: (outline-minor-mode)
;; outline-regexp: ";;; \\\*+"
;; outline-promotion-headings: (";;; *" ";;; **" ";;; ***" ";;; ****")
;; End:

