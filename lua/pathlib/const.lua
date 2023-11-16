local M = {}

M.IS_WINDOWS = vim.fn.has("win32") == 1 or vim.fn.has("win32unix") == 1

---@enum PathlibBitOps
M.bitops = {
  OR = 1,
  XOR = 3,
  AND = 4,
}

---Bitwise operator for uint32
---@param a integer
---@param b integer
---@param oper PathlibBitOps
---@return integer
M.bitoper = function(a, b, oper)
  local s
  local r, m = 0, 2 ^ 31
  repeat
    s, a, b = a + b + m, a % m, b % m
    r, m = r + m * oper % (s - a - b), m / 2
  until m < 1
  return r
end

---@enum PathlibPathEnum
M.path_module_enum = {
  PathlibPath = "PathlibPath",
  PathlibPosix = "PathlibPosix",
  PathlibWindows = "PathlibWindows",
}

---Return the portion of the file's mode that can be set by os.chmod()
---@param mode integer
---@return integer
M.fs_imode = function(mode)
  return M.bitoper(mode, tonumber("0o7777", 8), M.bitops.AND)
end

---Return the portion of the file's mode that can be set by os.chmod()
---@param mode integer
---@return integer
M.fs_ifmt = function(mode)
  return M.bitoper(mode, tonumber("0o170000", 8), M.bitops.AND)
end

---@enum PathlibModeEnum
M.fs_mode_enum = {
  S_IFDIR = 16384, -- 0o040000  # directory
  S_IFCHR = 8192, -- 0o020000  # character device
  S_IFBLK = 24576, -- 0o060000  # block device
  S_IFREG = 32768, -- 0o100000  # regular file
  S_IFIFO = 4096, -- 0o010000  # fifo (named pipe)
  S_IFLNK = 40960, -- 0o120000  # symbolic link
  S_IFSOCK = 49152, -- 0o140000  # socket file
}

---@enum PathlibPermissionEnum
M.fs_permission_enum = {
  S_ISUID = 2048, -- 0o4000  # set UID bit
  S_ISGID = 1024, -- 0o2000  # set GID bit
  S_ENFMT = 1024, -- S_ISGID # file locking enforcement
  S_ISVTX = 512, -- 0o1000  # sticky bit
  S_IREAD = 256, -- 0o0400  # Unix V7 synonym for S_IRUSR
  S_IWRITE = 128, -- 0o0200 # Unix V7 synonym for S_IWUSR
  S_IEXEC = 64, -- 0o0100  # Unix V7 synonym for S_IXUSR
  S_IRWXU = 448, -- 0o0700  # mask for owner permissions
  S_IRUSR = 256, -- 0o0400  # read by owner
  S_IWUSR = 128, -- 0o0200  # write by owner
  S_IXUSR = 64, -- 0o0100  # execute by owner
  S_IRWXG = 56, -- 0o0070  # mask for group permissions
  S_IRGRP = 32, -- 0o0040  # read by group
  S_IWGRP = 16, -- 0o0020  # write by group
  S_IXGRP = 8, -- 0o0010  # execute by group
  S_IRWXO = 7, -- 0o0007  # mask for others (not in group) permissions
  S_IROTH = 4, -- 0o0004  # read by others
  S_IWOTH = 2, -- 0o0002  # write by others
  S_IXOTH = 1, -- 0o0001  # execute by others
}

---Check if `mode_string` is a valid representation of permission string. (Eg `rwxrwxrwx`)
---@param mode_string string # "rwxrwxrwx" or '-' where permission not allowed
---@return boolean
M.check_permission_string = function(mode_string)
  if type(mode_string) ~= "string" then
    return false
  end
  if #mode_string ~= 9 then
    return false
  end
  local modes = { "r", "w", "x" }
  local index = 0
  for value in mode_string:gmatch(".") do
    if value ~= "-" and modes[index % 3 + 1] ~= value then
      return false
    end
    index = index + 1
  end
  return true
end

---Return integer of permission representing. Assert `M.check_permission_string` beforehand or this function will not work as expected.
---@param mode_string string
---@return integer
M.permission_from_string = function(mode_string)
  local result = 0
  for value in mode_string:gmatch(".") do
    result = result * 2
    if value ~= "-" then
      result = result + 1
    end
  end
  return result
end

return M
