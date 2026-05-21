// JavaScript source code
function scrollToDashboard() {
    document.getElementById("dashboard").scrollIntoView({
        behavior: "smooth"
    });
}

function createGroup() {
    const groupName = document.getElementById("groupName").value;
    const weeklyAmount = document.getElementById("weeklyAmount").value;
    const membersText = document.getElementById("members").value;

    let members = membersText
        .split("\n")
        .map(m => m.trim())
        .filter(m => m.length > 0);

    if (members.length < 2) {
        alert("Please enter at least 2 members.");
        return;
    }

    const randomizedMembers = shuffleArray([...members]);

    let html = `
        <h4>${groupName}</h4>
        <p><strong>Weekly Amount:</strong> $${weeklyAmount}</p>
        <p><strong>Total Members:</strong> ${members.length}</p>
        <hr style="margin: 15px 0;">
    `;

    randomizedMembers.forEach((member, index) => {
        html += `
            <div class="schedule-item">
                <span>Week ${index + 1}</span>
                <strong>${member}</strong>
            </div>
        `;
    });

    html += `
        <p style="margin-top:15px; color:#16a34a;">
            Payout order generated once and locked for this cycle.
        </p>
    `;

    document.getElementById("groupResult").innerHTML = html;
}

function shuffleArray(array) {
    for (let i = array.length - 1; i > 0; i--) {
        const randomIndex = Math.floor(Math.random() * (i + 1));
        [array[i], array[randomIndex]] = [array[randomIndex], array[i]];
    }
    return array;
}
