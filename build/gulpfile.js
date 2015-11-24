var gulp = require('gulp');
var eclint = require('eclint');
var jsonlint = require("gulp-jsonlint");

gulp.task('default', function() {
    var stream = gulp.src([
            '../src/**/*.json'
        ])
        .pipe(jsonlint())
        .pipe(jsonlint.reporter())
        .pipe(eclint.check({
            reporter: function(file, message) {
                //var relativePath = path.relative('.', file.path);
                console.error(file.path + ':', message);
            }
        }))
        .pipe(jsonlint.failAfterError())
        ;
    stream.on('finish', function() {
    });
    return stream;
});
