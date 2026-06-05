import { useEffect, useState } from 'react';
import './App.css';

const API = 'https://localhost:7210/api';

function App() {
    const [groups, setGroups] = useState([]);
    const [users, setUsers] = useState([]);
    const [selectedGroupId, setSelectedGroupId] = useState('');
    const [members, setMembers] = useState([]);
    const [payoutOrder, setPayoutOrder] = useState([]);
    const [message, setMessage] = useState('');

    const [groupName, setGroupName] = useState('Family Equb Group');
    const [weeklyAmount, setWeeklyAmount] = useState(200);
    const [maxMembers, setMaxMembers] = useState(4);
    const [startDate, setStartDate] = useState('');
    const [selectedUserId, setSelectedUserId] = useState('');

    useEffect(() => {
        loadGroups();
        loadUsers();
    }, []);

    async function loadGroups() {
        const res = await fetch(`${API}/groups`);
        const data = await res.json();
        setGroups(data);
    }

    async function loadUsers() {
        const res = await fetch(`${API}/users`);
        const data = await res.json();
        setUsers(data);
    }

    async function createGroup(e) {
        e.preventDefault();

        const res = await fetch(`${API}/groups/create`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                groupName,
                description: 'Created from frontend',
                createdByUserId: 1,
                contributionAmount: Number(weeklyAmount),
                currencyCode: 'USD',
                frequencyTypeId: 1,
                maxMembers: Number(maxMembers),
                startDate: startDate || new Date().toISOString()
            })
        });

        const data = await res.json();

        if (data.success) {
            setMessage(`Group created successfully. Group ID: ${data.groupId}`);
            await loadGroups();
            setSelectedGroupId(data.groupId);
        } else {
            setMessage(`Error: ${data.error}`);
        }
    }

    async function loadMembers(groupId) {
        if (!groupId) return;

        const res = await fetch(`${API}/groups/${groupId}/members`);
        const data = await res.json();
        setMembers(data);
    }

    async function loadPayoutOrder(groupId) {
        if (!groupId) return;

        const res = await fetch(`${API}/groups/${groupId}/payout-order`);
        const data = await res.json();
        setPayoutOrder(data);
    }

    async function handleGroupChange(e) {
        const groupId = e.target.value;
        setSelectedGroupId(groupId);
        setPayoutOrder([]);
        await loadMembers(groupId);
        await loadPayoutOrder(groupId);
    }

    async function addMember(e) {
        e.preventDefault();

        if (!selectedGroupId || !selectedUserId) {
            alert('Select group and user first.');
            return;
        }

        const res = await fetch(`${API}/groups/${selectedGroupId}/members`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                userId: Number(selectedUserId)
            })
        });

        const data = await res.json();

        if (data.success) {
            setMessage('Member added successfully.');
            await loadMembers(selectedGroupId);
        } else {
            setMessage(`Error: ${data.error}`);
        }
    }

    async function generatePayoutOrder() {
        if (!selectedGroupId) {
            alert('Select a group first.');
            return;
        }

        const res = await fetch(`${API}/groups/${selectedGroupId}/generate-payout-order`, {
            method: 'POST'
        });

        const data = await res.json();

        if (data.success) {
            setMessage(data.message);
            await loadGroups();
            await loadPayoutOrder(selectedGroupId);
        } else {
            setMessage(`Error: ${data.error}`);
        }
    }

    return (
        <>
            <header className="navbar">
                <div className="logo">Equb</div>
                <nav>
                    <a href="#create">Create Group</a>
                    <a href="#manage">Manage Group</a>
                    <a href="#groups">Groups</a>
                    <button className="btn-outline">Login</button>
                </nav>
            </header>

            <section className="hero">
                <div className="hero-text">
                    <h1>Modern Community Savings Platform</h1>
                    <p>
                        Create savings groups, add members, randomize payout order once,
                        and track your Equb group from one dashboard.
                    </p>
                    <a href="#create" className="btn-primary">Start Creating</a>
                </div>

                <div className="hero-card">
                    <h3>Local MVP Status</h3>
                    <p className="small-text">Frontend + Backend + SQL Server</p>
                    <h2>Connected</h2>

                    <div className="status-row">
                        <span>Groups</span>
                        <strong>{groups.length}</strong>
                    </div>

                    <div className="status-row">
                        <span>Users</span>
                        <strong>{users.length}</strong>
                    </div>

                    <div className="status-row">
                        <span>Status</span>
                        <strong className="green">Active</strong>
                    </div>
                </div>
            </section>

            <section id="create" className="section">
                <h2>Create Group</h2>

                <div className="dashboard">
                    <div className="panel">
                        <h3>Group Details</h3>

                        <form onSubmit={createGroup}>
                            <label>Group Name</label>
                            <input
                                value={groupName}
                                onChange={(e) => setGroupName(e.target.value)}
                                required
                            />

                            <label>Weekly Amount</label>
                            <input
                                type="number"
                                value={weeklyAmount}
                                onChange={(e) => setWeeklyAmount(e.target.value)}
                                required
                            />

                            <label>Max Members</label>
                            <input
                                type="number"
                                value={maxMembers}
                                onChange={(e) => setMaxMembers(e.target.value)}
                                required
                            />

                            <label>Start Date</label>
                            <input
                                type="date"
                                value={startDate}
                                onChange={(e) => setStartDate(e.target.value)}
                            />

                            <button className="btn-primary full" type="submit">
                                Create Group
                            </button>
                        </form>

                        {message && <p className="success-message">{message}</p>}
                    </div>

                    <div className="panel">
                        <h3>Saved Groups</h3>

                        <div className="result-box">
                            {groups.length === 0 && <p>No groups yet.</p>}

                            {groups.map(group => (
                                <div className="schedule-item" key={group.groupId}>
                                    <span>{group.groupName}</span>
                                    <strong>${group.contributionAmount}</strong>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>
            </section>

            <section id="manage" className="section light">
                <h2>Manage Group</h2>

                <div className="dashboard">
                    <div className="panel">
                        <h3>Select Group</h3>

                        <label>Group</label>
                        <select value={selectedGroupId} onChange={handleGroupChange}>
                            <option value="">-- Select Group --</option>
                            {groups.map(group => (
                                <option key={group.groupId} value={group.groupId}>
                                    {group.groupName}
                                </option>
                            ))}
                        </select>

                        <h3 style={{ marginTop: '25px' }}>Add Member</h3>

                        <form onSubmit={addMember}>
                            <label>User</label>
                            <select
                                value={selectedUserId}
                                onChange={(e) => setSelectedUserId(e.target.value)}
                            >
                                <option value="">-- Select User --</option>
                                {users.map(user => (
                                    <option key={user.userId} value={user.userId}>
                                        {user.firstName} {user.lastName} - {user.email}
                                    </option>
                                ))}
                            </select>

                            <button className="btn-primary full" type="submit">
                                Add Member
                            </button>
                        </form>

                        <button className="btn-primary full" onClick={generatePayoutOrder}>
                            Generate Payout Order Once
                        </button>
                    </div>

                    <div className="panel">
                        <h3>Group Members</h3>

                        <div className="result-box">
                            {members.length === 0 && <p>No members loaded.</p>}

                            {members.map(member => (
                                <div className="schedule-item" key={member.groupMemberId}>
                                    <span>
                                        {member.firstName} {member.lastName}
                                    </span>
                                    <strong>{member.statusName}</strong>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>
            </section>

            <section id="groups" className="section">
                <h2>Payout Order</h2>

                <div className="panel">
                    <h3>Locked Order</h3>

                    <div className="result-box">
                        {payoutOrder.length === 0 && <p>No payout order generated yet.</p>}

                        {payoutOrder.map(item => (
                            <div className="schedule-item" key={item.groupMemberId}>
                                <span>Position {item.payoutPosition}</span>
                                <strong>
                                    {item.firstName} {item.lastName}
                                </strong>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            <footer>
                <p>Equb Savings Platform © 2026</p>
            </footer>
        </>
    );
}

export default App;