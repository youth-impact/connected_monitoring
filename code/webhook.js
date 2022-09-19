// https://developers.google.com/apps-script/guides/triggers#onedite
// https://developers.google.com/apps-script/reference/url-fetch/url-fetch-app
// https://stackoverflow.com/questions/66154780/send-a-post-request-using-google-apps-script
// https://stackoverflow.com/questions/58359417/you-do-not-have-permission-to-call-urlfetchapp-fetch

function atEdit(e) {
  var sheets = ['github', 'data'];
  var sheet_now = e.range.getSheet().getName();
  var enabled = e.source.getSheetByName('github').getRange('B2').getValue();

  if (enabled == 1 && sheets.includes(sheet_now)) {
    var repo_url = e.source.getSheetByName('github').getRange('A2').getValue();
    var url = repo_url.replace('github\.com', 'api.github.com/repos') + '/dispatches';

    var pat_file = DriveApp.getFileById('1xOU3teX79HsTTljvdjfn9vUH4__iVoyy');
    var pat = pat_file.getBlob().getDataAsString();
    var auth = 'Bearer ' + pat;

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
}
