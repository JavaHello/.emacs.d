;;; codex.el -*- lexical-binding: t; -*-

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

(provide 'my-codex)
