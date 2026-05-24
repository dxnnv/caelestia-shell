pragma Singleton

import QtQuick

QtObject {
    id: root

    function run(args: var, opts: var): var {
        opts = opts || {};
        return new Promise(resolve => {
            const proc = Qt.createQmlObject("import Quickshell; import Quickshell.Io; Process {}", root);
            const out = Qt.createQmlObject("import Quickshell.Io; StdioCollector {}", proc);
            const err = Qt.createQmlObject("import Quickshell.Io; StdioCollector {}", proc);

            proc.command = args;
            if (opts.cwd)
                proc.workingDirectory = opts.cwd;
            if (opts.env)
                proc.environment = opts.env;
            if (opts.mergeStderr === true)
                proc.redirectStderrToStdout = true;
            if (opts.input !== undefined && opts.input !== null)
                proc.stdinText = String(opts.input);

            proc.stdout = out;
            proc.stderr = err;

            let outDone = false;
            let errDone = false;
            let exited = false;
            let exitCode = null;

            function tryFinish(): void {
                if (!outDone || !errDone || !exited)
                    return;

                const result = {
                    code: exitCode,
                    stdout: out.text,
                    stderr: err.text
                };
                out.destroy();
                err.destroy();
                proc.destroy();
                resolve(result);
            }

            out.streamFinished.connect(() => {
                outDone = true;
                tryFinish();
            });
            err.streamFinished.connect(() => {
                errDone = true;
                tryFinish();
            });
            proc.exited.connect(code => {
                exitCode = code;
                exited = true;
                tryFinish();
            });

            proc.running = true;
        });
    }

    function sh(cmd: string, opts: var): var {
        return run(["bash", "-lc", cmd], opts);
    }

    function must(args: var, opts: var): var {
        return run(args, opts).then(result => {
            if (result.code !== 0)
                throw new Error(`Process failed (${result.code}): ${result.stderr || result.stdout}`);
            return result.stdout;
        });
    }

    function requireSh(cmd: string, opts: var): var {
        return must(["bash", "-lc", cmd], opts);
    }
}
