-- https://stackoverflow.com/a/22965061
select timestamp '2000-01-01 00:00:00' +
       random() * (NOW() -
                   timestamp '2000-01-01 00:00:00')