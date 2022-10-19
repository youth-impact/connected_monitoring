// https://developers.google.com/apps-script/guides/triggers#onedite
// https://developers.google.com/apps-script/reference/url-fetch/url-fetch-app
// https://stackoverflow.com/questions/66154780/send-a-post-request-using-google-apps-script
// https://stackoverflow.com/questions/58359417/you-do-not-have-permission-to-call-urlfetchapp-fetch

function dispatch(repo_url) {
  var url = repo_url.replace('github\.com', 'api.github.com/repos') + '/dispatches';
  var pat_file = DriveApp.getFileById('1xOU3teX79HsTTljvdjfn9vUH4__iVoyy');
  var auth = 'Bearer ' + pat_file.getBlob().getDataAsString();

  var headers = {
    'Accept': 'application/vnd.github+json',
    'Authorization': auth
  };
  var data = {
    'event_type': 'webhook'
  };
  var options = {
    'method': 'post',
    'contentType': 'application/json',
    'headers': headers,
    'payload': JSON.stringify(data)
  };
  UrlFetchApp.fetch(url, options);
}

function at_edit(e) {
  var sheets = ['github', 'duplicates'];
  var sheet_now = e.range.getSheet().getName();
  var gh = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('github');
  var enabled = gh.getRange('B2').getValue();

  if (enabled == 1 && sheets.includes(sheet_now)) {
    var repo_url = gh.getRange('A2').getValue();
    dispatch(repo_url);
  }
}

function at_change(e) {
  user_now = e.user.getEmail();
  var gh = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('github');
  var enabled = gh.getRange('B2').getValue();

  Logger.log(e.authMode);
  Logger.log(e.changeType);
  Logger.log(user_now);

  // should correspond to changes made by surveycto and not via github actions
  if (enabled == 1 && user_now == '' && e.changeType == 'INSERT_ROW') {
    var repo_url = gh.getRange('A2').getValue();
    dispatch(repo_url);
  }
}
