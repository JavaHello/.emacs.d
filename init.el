;;; init.el -*- lexical-binding: t; -*-

;; 配置字符集
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

(setq custom-file "~/.emacs.custom.el")
;; 启用语法高亮
(global-font-lock-mode 1)
;; 高亮当前行
(global-hl-line-mode 1)


;; mac meta
(when (eq system-type 'darwin) ;; mac specific settings
  (setq mac-option-modifier 'alt)
  (setq mac-command-modifier 'meta)
  (global-set-key [kp-delete] 'delete-char) ;; sets fn-delete to be right-delete
  )


;; (global-tab-line-mode t); 顶部显示 tab
(global-auto-revert-mode t) ; 外部程序修改文件自动刷新


(column-number-mode t) ; 启用列号显示
(electric-pair-mode t) ; 自动补全括号
(size-indication-mode t) ; 显示缓冲区大小
(global-hl-line-mode t) ; 高亮显示当前行


;; 判断是 gui 设置字体
(when (display-graphic-p)
  ;; 英文字体
  (pcase system-type
    ('darwin
     (set-face-attribute 'default nil :font "CaskaydiaMono Nerd Font Mono-14")
     (set-fontset-font t 'han "PingFang SC")
     (set-fontset-font t 'cjk-misc "PingFang SC")
     (set-fontset-font t 'kana "PingFang SC"))

    ('gnu/linux
     (set-face-attribute 'default nil :font "CaskaydiaMono Nerd Font Mono-13")
     (set-fontset-font t 'han "Noto Sans Mono CJK SC")
     (set-fontset-font t 'cjk-misc "Noto Sans Mono CJK SC")
     (set-fontset-font t 'kana "Noto Sans Mono CJK SC"))

    ('windows-nt
     (set-face-attribute 'default nil :font "CaskaydiaMono Nerd Font Mono-13")
     (set-fontset-font t 'han "Microsoft YaHei UI")
     (set-fontset-font t 'cjk-misc "Microsoft YaHei UI")
     (set-fontset-font t 'kana "Microsoft YaHei UI"))))




(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("gnu"   . "https://elpa.gnu.org/packages/")))

(package-initialize)

;; 主题
(use-package gruvbox-theme
  :ensure t
  :config
  (load-theme 'gruvbox-dark-medium t))


(add-to-list 'load-path "~/.emacs.d/simpc-mode")
(require 'simpc-mode)
;; Automatically enabling simpc-mode on files with extensions like .h, .c, .cpp, .hpp
(add-to-list 'auto-mode-alist '("\\.[hc]\\(pp\\)?\\'" . simpc-mode))

(require 'eglot)
;; 让 .rs 文件使用内置 rust-ts-mode
(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-ts-mode))

;; 打开 Rust 文件时自动启动内置 Eglot
(add-hook 'rust-ts-mode-hook #'eglot-ensure)

;; 如果 Emacs 找不到 rust-analyzer，可显式指定
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((rust-ts-mode) . ("rust-analyzer"))))

;; 默认启动 server 模式，git 提交填消息时会使用
(setenv "GIT_EDITOR" "emacsclient")
(require 'vc)
(require 'server)
(unless (server-running-p)
  (server-start))

(require 'org-tempo)


(add-hook 'org-mode-hook
  (lambda ()
    (setq-local electric-pair-inhibit-predicate
                (lambda (c)
                  (if (char-equal c ?<) t
                    (electric-pair-default-inhibit c))))))
;; 第三方 plugin
;; (require 'diff-hl)
;; (global-diff-hl-mode)

(use-package diff-hl
  :hook (prog-mode . diff-hl-mode))

(use-package markdown-mode
  :ensure t
  :mode ("\\.md\\'" . markdown-mode))
  ;; :init
;;  (setq markdown-command "pandoc"))
(setq markdown-fontify-code-blocks-natively t)
(setq markdown-enable-math t)
(setq markdown-hide-urls nil)

(use-package magit
  :ensure t
  :commands (magit-status)
  :bind ("C-x g" . magit-status))

;; 其他配置
;; 额外保险：进入 vterm 时关闭
(add-hook 'vterm-mode-hook
          (lambda ()
            (display-line-numbers-mode 0)))

(defun my/disable-line-numbers-for-special-buffers ()
  (when (member (buffer-name) '("*Shell Command Output*" "*Async Shell Command*"))
    (display-line-numbers-mode 0)))

(add-hook 'after-change-major-mode-hook #'my/disable-line-numbers-for-special-buffers)

;; codex config
(defconst codex-buffer-name "*codex*"
  "Buffer name for interactive Codex vterm sessions.")

(defconst codex-async-buffer-name "*codex-async*"
  "Buffer name for asynchronous `codex exec` output.")

(defun codex--project-root ()
  "Return the current project root, or signal a user-facing error."
  (if-let ((project (project-current nil)))
      (project-root project)
    (user-error "Codex 必须在项目目录下启动")))

(defun codex--buffer ()
  "Return the interactive Codex buffer."
  (get-buffer-create codex-buffer-name))

(defun codex--display-buffer ()
  "Display the interactive Codex buffer."
  (display-buffer (codex--buffer)))

(defun codex--create-async-buffer ()
  "Create and return a unique asynchronous Codex output buffer."
  (get-buffer-create
   (generate-new-buffer-name codex-async-buffer-name)))

(defun codex--display-async-buffer (buffer)
  "Display asynchronous Codex output BUFFER."
  (display-buffer buffer))

(defun codex--append-output (buffer text)
  "Append TEXT to asynchronous Codex output BUFFER."
  (when (and text (not (string-empty-p text)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t)
            (moving (= (point) (point-max))))
        (save-excursion
          (goto-char (point-max))
          (insert text))
        (when moving
          (goto-char (point-max)))))))

(defun codex ()
  "Open Codex CLI in a project-root vterm buffer."
  (interactive)
  (let ((default-directory (file-name-as-directory (codex--project-root))))
    (vterm codex-buffer-name)
    (vterm-send-string "codex")
    (vterm-send-return)))

(defun codex-here ()
  "Open Codex CLI from the current project root."
  (interactive)
  (codex))

(defun codex--ensure-editable-file-in-project ()
  "Ensure the current buffer visits a saved file inside the current project."
  (unless buffer-file-name
    (user-error "当前 buffer 没有关联文件，无法发送路径和选区位置"))
  (let* ((project-root (file-name-as-directory
                        (file-truename (codex--project-root))))
         (file-path (file-truename buffer-file-name)))
    (unless (file-in-directory-p file-path project-root)
      (user-error "拒绝发送项目根外文件: %s" buffer-file-name))
    (when (buffer-modified-p)
      (unless (y-or-n-p (format "Buffer %s 未保存，先保存再发送？ "
                                (buffer-name)))
        (user-error "已取消发送；请先保存 buffer"))
      (save-buffer))
    (cons project-root file-path)))

(defun codex--region-location (start end)
  "Return a prompt fragment describing region START..END by file path and position."
  (save-restriction
    (widen)
    (let* ((paths (codex--ensure-editable-file-in-project))
           (project-root (car paths))
           (file-path (file-relative-name (cdr paths) project-root))
           (start-line (line-number-at-pos start))
           (end-line (line-number-at-pos end))
           ;; Use 1-based buffer positions to avoid column ambiguity with tabs
           ;; and wide characters. END remains exclusive, matching Emacs regions.
           (start-pos start)
           (end-pos end))
      (format
       (concat "File: %s\n"
               "Selection: characters %d to %d (1-based, Emacs region semantics; end is exclusive), spanning lines %d to %d\n"
               "Interpret the selection as the Emacs region between these character positions in the saved file.\n"
               "Read the file from disk and focus on that range instead of expecting the selected text inline.")
       file-path
       start-pos end-pos
       start-line end-line))))

(defun codex-edit-region (start end instruction)
  "Asynchronously send file path and selected region position to `codex exec`."
  (interactive "r\nsInstruction: ")
  (let* ((location (codex--region-location start end))
         (prompt (format "%s\n\n%s" instruction location))
         (default-directory (file-name-as-directory (codex--project-root)))
         (output-buffer (codex--create-async-buffer))
         (proc
          (make-process
           :name (generate-new-buffer-name "codex-edit-region")
           :buffer nil
           :command '("sh" "-lc" "codex exec - 2>&1")
           :connection-type 'pipe
           :coding 'utf-8-unix
           :noquery t
           :filter
           (lambda (_process chunk)
             (codex--append-output output-buffer chunk))
           :sentinel
           (lambda (process event)
             (when (memq (process-status process) '(exit signal))
               (let ((code (process-exit-status process)))
                 (codex--append-output
                  output-buffer
                  (format "\n[codex exit %s] %s"
                          code
                          (string-trim event)))
                 (unless (zerop code)
                   (message "codex exec failed: %s (%s)"
                            code (string-trim event)))))))))
    (codex--append-output
     output-buffer
     (format "\n\n[%s] codex exec started in %s\n"
             (format-time-string "%F %T")
             default-directory))
    (codex--display-async-buffer output-buffer)
    (process-send-string proc prompt)
    (process-send-eof proc)
    (message "codex exec started...")))
;; keymap
(global-set-key (kbd "M-RET") 'toggle-frame-fullscreen)
