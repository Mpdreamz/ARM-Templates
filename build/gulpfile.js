var gulp = require('gulp');
var eclint = require('eclint');



gulp.task('default', function() {
    var hasErrors = false;
    var stream = gulp.src([
            '*',
            '../src/**/*.json'
        ])
        .pipe(eclint.check({
            reporter: function(file, message) {
                hasErrors = true;
                //var relativePath = path.relative('.', file.path);
                console.error(file.path + ':', message);
            }
        }));
    stream.on('finish', function() {
        if (hasErrors) {
            process.exit(1);
        }
    });
    return stream;
});
