import { spawn } from 'child_process'
import * as path from 'path'

const child = spawn('node', [path.join(__dirname, 'runner.js')], { cwd: '/tmp/a' });

child.stdout.on('data', (data) => {
  console.log(`child stdout:\n${data}`);
});

child.stderr.on('data', (data) => {
  console.error(`child stderr:\n${data}`);
});

child.on('exit', function (code, signal) {
  console.log('child process exited with ' +
              `code ${code} and signal ${signal}`);
});