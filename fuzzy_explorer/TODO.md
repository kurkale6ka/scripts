# Recursive lookup?
example:
  - `ex -g ssh`
  - delete 'ssh' query, try another one => will most likely fail since only filtering the 'ssh' subset
  - try on all files: find (+ grep if no matching filenames)
  - loop till we validate a result or ESC

=> I am not going to bother since I've never needed it in practice

# Package with pyproject
add `main()`...

# Multiple args?
Not sure about that.

- split `@ARGV` with `-e`? # or python equivalent :-)
- `rg -Sl patt1 | ... | xargs rg -S pattn`
- also for `fd ... $1`
