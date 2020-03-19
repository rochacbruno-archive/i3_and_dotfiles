-- Save this file to ~/.config/micro/init.lua
-- requirements:
--   Python3
--     - isort
--     - black
--     - flake8
--     - ipython
--   Rust
--     - cargo-play
--     - evcxr_repl
--     - clippy
--     - fmt

VERSION = "0.0.2"

local micro = import("micro")
local config = import("micro/config")
local shell = import("micro/shell")
-- local buffer = import("micro/buffer")

function init()
    -- this will modify the bindings.json file
    -- true means overwrite any existing binding
    config.TryBindKey("Alt-b", "lua:initlua.build", true)
    config.TryBindKey("Alt-t", "lua:initlua.test", true)
    config.TryBindKey("Alt-f", "lua:initlua.format", true)
    config.TryBindKey("Alt-i", "lua:initlua.repl", true)
    config.TryBindKey("Alt-l", "lua:initlua.lint", true)
    config.TryBindKey("Alt-y", "lua:initlua.sort_imports", true)
    -- TODO: Add rename variable utility (example below)
    -- https://github.com/micro-editor/go-plugin/blob/8d7c7dfd4488e25a2e3f5eb37aac3ccacc0143bc/go.lua#L44
end

-- utils

function setContains(set, key)
    return set[key] ~= nil
end

-- actions

function build(bp)

    bp:Save()
    local buf = bp.Buf

    _command = {}
    _command["go"] = "go run " .. buf.Path
    -- cargo install cargo-play
    _command["rust"] = "cargo play " .. buf.Path
    _command["python"] = "python3 " .. buf.Path

    -- the true means run in the foreground
    -- the false means send output to stdout (instead of returning it)
    shell.RunInteractiveShell(_command[buf:FileType()], true, false)
    -- TODO: Instead of closing editor to open new shell
    -- This ideally will have an option to get the results
    -- And then show in the same window in a new hsplit buffer

    -- if buf:FileType() == "go" then
    --     shell.RunInteractiveShell("go run " .. buf.Path, true, false)
    -- end
end

function test(bp)
    bp:Save()
    local buf = bp.Buf

    _command = {}
     _command["go"] = "go test -v " .. buf.Path

    -- TODO: make cargo to run specific file tests
    _command["rust"] = "cargo test -v --color always "
    _command["python"] = "python3 -m pytest -svx " .. buf.Path

    -- the true means run in the foreground
    -- the false means send output to stdout (instead of returning it)
    shell.RunInteractiveShell(_command[buf:FileType()], true, false)

end

function format(bp)
    local buf = bp.Buf
    local filetype = buf:FileType()

    _command = {}
    _command["go"] = "go fmt -w" .. buf.Path
    _command["rust"] = "rustfmt -v -l --backup --edition=2018 " .. buf.Path
    _command["python"] = "black -l 79 " .. buf.Path

    if not setContains(_command, filetype) then
        return
    end

    bp:Save()
    local output, err = shell.RunCommand(_command[filetype])
    if err ~= nil then
        micro.InfoBar():Error(err)
        return
    end

    -- micro.InfoBar():Message(output)
    buf:ReOpen()
end

function sort_imports(bp)
    local buf = bp.Buf
    local filetype = buf:FileType()

    _command = {}
    _command["go"] = "goimports -w " .. buf.Path
    -- _command["rust"] = "rustfmt -v -l --backup --edition=2018 " .. buf.Path
    _command["python"] = "isort " .. buf.Path

    if not setContains(_command, filetype) then
        return
    end

    bp:Save()
    local output, err = shell.RunCommand(_command[filetype])
    if err ~= nil then
        micro.InfoBar():Error(err)
        return
    end

    -- micro.InfoBar():Message(output)
    buf:ReOpen()
end

function repl(bp)
    bp:Save()
    local buf = bp.Buf

    _command = {}
    -- _command["go"] = "go ? " .. buf.Path
    -- cargo install evcxr_repl
    _command["rust"] = "evcxr "
    -- TODO: make evcxr interactive? print usage info before opening
    _command["python"] = "ipython -i " .. buf.Path

    -- the true means run in the foreground
    -- the false means send output to stdout (instead of returning it)
    shell.RunInteractiveShell(_command[buf:FileType()], true, false)
    -- TODO: how to force reload of buffer after format?

end

function lint(bp)
    bp:Save()
    local buf = bp.Buf

    _command = {}
    -- _command["go"] = "go ? " .. buf.Path
    _command["rust"] = "cargo-clippy "
    _command["python"] = "flake8 " .. buf.Path

    -- the true means run in the foreground
    -- the false means send output to stdout (instead of returning it)
    shell.RunInteractiveShell(_command[buf:FileType()], true, false)

end

function onSave(bp)
    sort_imports(bp)
    format(bp)

    -- TODO: Use config to decide what to run on save.
    -- example: https://github.com/micro-editor/go-plugin/blob/8d7c7dfd4488e25a2e3f5eb37aac3ccacc0143bc/go.lua#L10
    -- if bp.Buf:FileType() == "go" then
        -- if bp.Buf.Settings["go.goimports"] then
            -- goimports(bp)
        -- elseif bp.Buf.Settings["go.gofmt"] then
            -- gofmt(bp)
        -- end
    -- end
    return true
end