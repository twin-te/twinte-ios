if (
  document
    .querySelector("#main-portlet-title")
    .textContent.includes("履修登録・登録状況照会")
) {
  const insertAfter = (newNode, referenceNode) =>
    referenceNode.parentNode.insertBefore(newNode, referenceNode.nextSibling);
  const b = document.createElement("button");
  b.append(document.createTextNode("Twin:teにインポート"));
  b.onclick = () => {
    const now = document.querySelector("[name=TimeoutForm]+table td").innerText;
    if (window.confirm(`${now}の時間割をインポートします`)) {
      const lectures = Array.from(
        document.querySelectorAll(".rishu-koma td td")
      )
        .map(el => el.innerText.split("\n")[0])
        .filter((el, i, self) => el !== "\u00A0" && self.indexOf(el) === i);
      postToTwinte(lectures);
    }
  };
  insertAfter(b, document.querySelector("#main-portlet-title"));
}

const postToTwinte = async lectures => {
  await Promise.all(
    lectures.map(async l => {
      await fetch("https://dev.api.twinte.net/timetables/2019", {
        method: "POST",
        body: JSON.stringify({ lectureID: l }),
        headers: {
          "Content-Type": "application/json; charset=utf-8"
        },
        credentials: "include"
      });
    })
  );
  alert("Twin:teへのインポートが完了しました");
};
