(require 'ert)
(require 'pyimport)
(require 'shut-up)

(ert-deftest var-extraction ()
  "Ensure we parse pyflakes output for older pyflakes versions."
  (should
   (equal
    (pyimport--extract-unused-var "'foo' imported but unused")
    "foo")))

(ert-deftest var-extraction-new ()
  "Ensure we parse pyflakes output for recent pyflakes versions."
  (should
   (equal
    (pyimport--extract-unused-var "'foo.bar' imported but unused")
    "bar")))

(ert-deftest remove-import-case-sensitive ()
  "Ensure we remove imports case-sensitively"
  (with-temp-buffer
    (insert "import cPickle as pickle")
    (pyimport--remove-import 1 "pickle")
    (should
     (equal (buffer-string) ""))))

(ert-deftest remove-on-line-first ()
  "We should remove the first occurrence, if present."
  (with-temp-buffer
    (insert "foo bar baz bar")
    (pyimport--remove-on-line "bar")
    (should
     (equal (buffer-string) "foo  baz bar"))))

(ert-deftest import-lines ()
  (with-temp-buffer
    (insert "from foo import bar\n"
            "import baz\n"
            "y = 1\n"
            "import quz.zox")
    (should (equal
             (pyimport--import-lines (current-buffer))
             '("from foo import bar"
               "import baz"
               "import quz.zox")))))

(ert-deftest import-lines-correct-buffer ()
  "Ensure we extract lines from the buffer passed in."
  (let ((buf (get-buffer-create "my-buffer")))
    (with-current-buffer buf
      (insert "import foo")
      
      (with-temp-buffer
        (insert "import bar")
        (let ((lines (pyimport--import-lines buf)))
          (should (equal lines '("import foo")))
          (should (equal (get-text-property 0 'pyimport-path (-first-item lines))
                         "my-buffer")))))))

(ert-deftest same-module ()
  (should
   (pyimport--same-module
    "from foo import x"
    "from foo import y, z"))
  (should
   (not (pyimport--same-module
         "from foo import x"
         "from foo.bar import x"))))

(ert-deftest buffers-in-mode ()
  (let ((buf1 (get-buffer-create "buf1"))
        (buf2 (get-buffer-create "buf2")))
    (shut-up
      (with-current-buffer buf1
        (python-mode))
      (with-current-buffer buf2
        (python-mode)))

    (let ((result (pyimport--buffers-in-mode 'python-mode)))
      (should
       (equal (list buf1 buf2)
              (--sort (string< (buffer-name it) (buffer-name other))
                      result))))
    
    (kill-buffer buf1)
    (kill-buffer buf2)))

(ert-deftest for-each-line ()
  (let (result-lines)
    (with-temp-buffer
      (insert "a\nb\nc\nd")
      (pyimport--for-each-line
        (push (pyimport--current-line) result-lines)))

    (setq result-lines (nreverse result-lines))
    (should
     (equal result-lines '("a" "b" "c" "d")))))
