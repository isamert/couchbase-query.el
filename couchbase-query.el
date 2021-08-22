;;; couchbase-query.el --- Inferior mode for cbq binary. -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Isa Mert Gurbuz

;; Author: Isa Mert Gurbuz <isamert@protonmail.com>
;; Version: 0.1
;; Homepage: https://github.com/isamert/couchbase-query.el
;; License: GPL-3.0-or-later
;; Package-Requires: ((emacs "27.1") (json-mode "1.5.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Evaluate Couchbase queries interactively inside Emacs.

;;; Code:

(require 'comint)
(require 'json-mode)


(defcustom couchbase-query-command
  "cbq"
  "Pat to `cbq' binary."
  :type 'string
  :group 'couchbase-query)

(defcustom couchbase-query-command-parameters
  '()
  "Parameters sent to `cbq' binary."
  :type 'string
  :group 'couchbase-query)

(defcustom couchbase-query-prompt-readonly
  t
  "If non-nil, couchbase query prompt is read-only."
  :type 'boolean
  :group 'couchbase-query)

(defvar couchbase-query--command-list
  '("ALIAS"
    "CONNECT"
    "COPYRIGHT"
    "DISCONNECT"
    "ECHO"
    "HELP"
    "POP"
    "PUSH"
    "QUIT"
    "EXIT"
    "REDIRECT"
    "REFRESH_CLUSTER_MAP"
    "SET"
    "SOURCE"
    "UNALIAS"
    "UNSET"
    "VERSION")
  "Command list for couchbase query.")

(defun couchbase-query--comint-bol? (point)
  (eq point
      (save-excursion
        (comint-bol)
        (skip-syntax-forward " " (point-at-eol))
        (point))))

(defun couchbase-query--current-command ()
  ""
  (save-excursion
    (comint-bol)
    (skip-syntax-forward " " (point-at-eol))
    (when (eq (char-after) ?\\)
      (forward-char))
    (thing-at-point 'symbol)))

;; Right now it only completes cbq commands. Maybe in the future it'll
;; do more if I start using queries more
(defun couchbase-query--completion-at-point ()
  (interactive)
  (let* ((bounds (bounds-of-thing-at-point 'symbol))
         (symbol (thing-at-point 'symbol))
         (start (or (car bounds) (point)))
         (end (or (cdr bounds) (point))))
    (cond
     ((or (couchbase-query--comint-bol? (1- start))
          (string= (upcase (couchbase-query--current-command)) "HELP"))
      (list start end couchbase-query--command-list . nil)))))

;;;###autoload
(define-derived-mode inferior-couchbase-query-mode comint-mode "CBQ"
  "Major mode for interactively evaluating Couchbase queries."
  (setq-local completion-ignore-case t)
  (setq-local comint-prompt-read-only couchbase-query-prompt-readonly)
  (add-hook 'completion-at-point-functions 'couchbase-query--completion-at-point nil 'local)
  (set (make-local-variable 'font-lock-defaults) '(json-font-lock-keywords-1 t)))

;;;###autoload
(defun couchbase-query (&optional buf-name)
  "Interactively evaluate Couchbase queries."
  (interactive)
  (let (old-point
        (buf-name (or buf-name "*cbq*")))
    (unless (comint-check-proc buf-name)
      (with-current-buffer (get-buffer-create buf-name)
        (unless (zerop (buffer-size))
          (setq old-point (point)))
        (apply
         #'make-comint-in-buffer
         "cbq"
         (current-buffer)
         couchbase-query-command
         nil
         couchbase-query-command-parameters)
        (inferior-couchbase-query-mode)))
    (pop-to-buffer-same-window buf-name)
    (when old-point
      (push-mark old-point))))

(provide 'couchbase-query)
;;; couchbase-query.el ends here
