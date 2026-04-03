import React, { useEffect, useMemo, useState } from 'react';
import {
  LayoutDashboard,
  Users,
  Wrench,
  ClipboardList,
  CreditCard,
  Star,
  BarChart3,
  Settings,
  LogOut,
  Menu,
  X,
  MapPin,
  Shield,
  Plus,
  Pencil,
  Trash2,
  RefreshCcw,
  Search,
} from 'lucide-react';

const apiBaseCandidates = Array.from(
  new Set(
    [
      process.env.REACT_APP_API_BASE_URL,
      'http://localhost:5000/api',
      'http://127.0.0.1:5000/api',
      '/api',
    ].filter(Boolean)
  )
);

const TAB_ENTITY_MAP = {
  Dashboard: null,
  Verification: null,
  Users: 'users',
  Repairmen: 'repairmen',
  Services: 'services',
  Bookings: 'bookings',
  Payments: 'payments',
  Reviews: 'reviews',
  Reports: 'bookings',
  Settings: 'accounts',
  Accounts: 'accounts',
  Locations: 'locations',
  Cities: 'cities',
};

const MENU_ITEMS = [
  { name: 'Dashboard', icon: <LayoutDashboard size={20} /> },
  { name: 'Verification', icon: <Shield size={20} /> },
  { name: 'Users', icon: <Users size={20} /> },
  { name: 'Repairmen', icon: <Wrench size={20} /> },
  { name: 'Services', icon: <Settings size={20} /> },
  { name: 'Bookings', icon: <ClipboardList size={20} /> },
  { name: 'Payments', icon: <CreditCard size={20} /> },
  { name: 'Reviews', icon: <Star size={20} /> },
  { name: 'Accounts', icon: <Shield size={20} /> },
  { name: 'Locations', icon: <MapPin size={20} /> },
  { name: 'Cities', icon: <MapPin size={20} /> },
  { name: 'Reports', icon: <BarChart3 size={20} /> },
  { name: 'Settings', icon: <Settings size={20} /> },
];

const ENTITY_TEMPLATES = {
  services: {
    service_name: '',
    description: '',
    base_price: 0,
    category: 'mechanic',
    is_active: true,
  },
  users: {
    name: '',
    phone: '',
    address: '',
    account_id: '',
  },
  repairmen: {
    name: '',
    phone: '',
    skills: [],
    availability_status: 'available',
    account_id: '',
  },
  accounts: {
    username: '',
    email: '',
    role: 'admin',
    is_active: true,
  },
  locations: {
    repairman_id: '',
    latitude: 0,
    longitude: 0,
  },
  cities: {
    name: '',
    state: '',
    country: 'India',
    is_active: true,
  },
};

const ENTITY_HELP_TEXT = {
  services: 'Use service_name, description, base_price, category, and is_active. Categories like mechanic, plumber, electrician, cleaning, carpenter, and ac repair show best in the app.',
  cities: 'Add one city per record. Users and repairmen will see active cities in their signup dropdown.',
};

const getAuthToken = () =>
  window.localStorage.getItem('adminToken') || window.localStorage.getItem('token') || '';

const fetchFromApi = async (path, options = {}) => {
  let lastError = null;
  const attempts = [];
  const token = getAuthToken();
  const headers = new Headers(options.headers || {});

  if (token && !headers.has('Authorization')) {
    headers.set('Authorization', `Bearer ${token}`);
  }

  for (const base of apiBaseCandidates) {
    try {
      const response = await fetch(`${base}${path}`, {
        ...options,
        headers,
      });
      if (!response.ok) {
        const message = `Failed ${response.status} for ${base}${path}`;
        attempts.push(message);
        lastError = new Error(message);
        continue;
      }

      const raw = await response.text();
      try {
        return JSON.parse(raw);
      } catch (error) {
        const preview = (raw || '').slice(0, 80).replace(/\s+/g, ' ');
        const message = `Non-JSON response for ${base}${path}: ${preview}`;
        attempts.push(message);
        lastError = new Error(message);
        continue;
      }
    } catch (error) {
      attempts.push(`${base}${path}: ${error.message}`);
      lastError = error;
    }
  }

  const details = attempts.length ? ` Attempts: ${attempts.join(' | ')}` : '';
  throw new Error((lastError?.message || `Unable to load ${path}`) + details);
};

const normalizeDisplayValue = (value) => {
  if (value === null || value === undefined) return '-';
  if (typeof value === 'boolean') return value ? 'true' : 'false';
  if (typeof value === 'object') return JSON.stringify(value);
  return String(value);
};

const Dashboard = () => {
  const [activeTab, setActiveTab] = useState('Dashboard');
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  const [stats, setStats] = useState({
    totalRevenue: 0,
    activeUsers: 0,
    activeRepairmen: 0,
    pendingBookings: 0,
    completedBookings: 0,
    activeServices: 0,
    avgRating: 0,
  });
  const [totals, setTotals] = useState({});
  const [activity, setActivity] = useState([]);
  const [tableItems, setTableItems] = useState([]);
  const [verificationItems, setVerificationItems] = useState([]);
  const [hasCrudApi, setHasCrudApi] = useState(true);

  const [isStatsLoading, setIsStatsLoading] = useState(true);
  const [isActivityLoading, setIsActivityLoading] = useState(false);
  const [isTableLoading, setIsTableLoading] = useState(false);
  const [statsError, setStatsError] = useState('');
  const [activityError, setActivityError] = useState('');
  const [tableError, setTableError] = useState('');
  const [verificationError, setVerificationError] = useState('');

  const [modalOpen, setModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState('create');
  const [modalTitle, setModalTitle] = useState('');
  const [editingId, setEditingId] = useState('');
  const [jsonInput, setJsonInput] = useState('{}');
  const [modalError, setModalError] = useState('');
  const [isSaving, setIsSaving] = useState(false);
  const [isVerificationLoading, setIsVerificationLoading] = useState(false);
  const [reviewState, setReviewState] = useState({});

  const activeEntity = TAB_ENTITY_MAP[activeTab];

  const columns = useMemo(() => {
    const source = activeTab === 'Dashboard' ? activity : tableItems;
    const keys = new Set(['id']);
    source.forEach((item) => Object.keys(item || {}).forEach((key) => keys.add(key)));
    return Array.from(keys);
  }, [activeTab, activity, tableItems]);

  const formatCurrency = (amount) =>
    new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      maximumFractionDigits: 0,
    }).format(Number(amount || 0));

  const loadSummary = async () => {
    try {
      setIsStatsLoading(true);
      setStatsError('');
      const data = await fetchFromApi('/admin/summary');
      setStats({
        totalRevenue: Number(data?.stats?.totalRevenue || 0),
        activeUsers: Number(data?.stats?.activeUsers || 0),
        activeRepairmen: Number(data?.stats?.activeRepairmen || 0),
        pendingBookings: Number(data?.stats?.pendingBookings || 0),
        completedBookings: Number(data?.stats?.completedBookings || 0),
        activeServices: Number(data?.stats?.activeServices || 0),
        avgRating: Number(data?.stats?.avgRating || 0),
      });
      setTotals(data?.totals || {});
    } catch (error) {
      setStatsError(`Unable to load dashboard stats. ${error.message}`);
    } finally {
      setIsStatsLoading(false);
    }
  };

  const loadDashboardActivity = async () => {
    try {
      setIsActivityLoading(true);
      setActivityError('');
      const data = await fetchFromApi('/admin/activity?tab=dashboard');
      setActivity(Array.isArray(data?.items) ? data.items : []);
    } catch (error) {
      setActivityError(`Unable to load dashboard activity. ${error.message}`);
    } finally {
      setIsActivityLoading(false);
    }
  };

  const loadEntities = async (entity, query = '') => {
    if (!entity) return;
    try {
      setIsTableLoading(true);
      setTableError('');
      const path = `/admin/entities/${entity}${query ? `?q=${encodeURIComponent(query)}` : ''}`;
      const data = await fetchFromApi(path);
      setTableItems(Array.isArray(data?.items) ? data.items : []);
      setHasCrudApi(true);
    } catch (error) {
      try {
        const fallback = await fetchFromApi(`/admin/activity?tab=${encodeURIComponent(activeTab)}`);
        setTableItems(Array.isArray(fallback?.items) ? fallback.items : []);
        setHasCrudApi(false);
        setTableError('Limited mode: backend is missing /admin/entities endpoints. Update/restart backend for full CRUD.');
      } catch (fallbackError) {
        setTableError(`Unable to load ${activeTab}. ${error.message}`);
      }
    } finally {
      setIsTableLoading(false);
    }
  };

  const loadVerifications = async () => {
    try {
      setIsVerificationLoading(true);
      setVerificationError('');
      const data = await fetchFromApi('/admin/verifications');
      setVerificationItems(Array.isArray(data?.items) ? data.items : []);
    } catch (error) {
      setVerificationError(`Unable to load verification queue. ${error.message}`);
    } finally {
      setIsVerificationLoading(false);
    }
  };

  useEffect(() => {
    loadSummary();
    loadDashboardActivity();
  }, []);

  useEffect(() => {
    if (activeTab === 'Dashboard') return;
    if (activeTab === 'Verification') {
      loadVerifications();
      return;
    }
    loadEntities(activeEntity, searchTerm);
  }, [activeTab]);

  const handleReviewVerification = async (repairmanId, decision) => {
    const rejectionReason =
      decision === 'reject'
        ? window.prompt('Enter rejection reason for this verification:', '') || ''
        : '';

    if (decision === 'reject' && !rejectionReason.trim()) {
      return;
    }

    try {
      setReviewState((current) => ({ ...current, [repairmanId]: decision }));
      await fetchFromApi(`/admin/verifications/${repairmanId}/review`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          decision,
          rejection_reason: rejectionReason,
        }),
      });
      await loadVerifications();
      await loadSummary();
      await loadDashboardActivity();
    } catch (error) {
      setVerificationError(`Unable to review verification. ${error.message}`);
    } finally {
      setReviewState((current) => {
        const next = { ...current };
        delete next[repairmanId];
        return next;
      });
    }
  };

  const openCreateModal = () => {
    if (!activeEntity || !hasCrudApi) return;
    setModalMode('create');
    setModalTitle(`Create ${activeTab} Record`);
    setEditingId('');
    setJsonInput(JSON.stringify(ENTITY_TEMPLATES[activeEntity] || {}, null, 2));
    setModalError('');
    setModalOpen(true);
  };

  const openEditModal = (item) => {
    setModalMode('edit');
    setModalTitle(`Edit ${activeTab} Record`);
    setEditingId(item.id);
    setModalError('');
    const { id, ...rest } = item;
    setJsonInput(JSON.stringify(rest, null, 2));
    setModalOpen(true);
  };

  const handleDelete = async (id) => {
    if (!activeEntity || !hasCrudApi) return;
    const okay = window.confirm(`Delete record "${id}" from ${activeTab}?`);
    if (!okay) return;

    try {
      await fetchFromApi(`/admin/entities/${activeEntity}/${id}`, { method: 'DELETE' });
      await loadEntities(activeEntity, searchTerm);
      await loadSummary();
    } catch (error) {
      setTableError(`Delete failed. ${error.message}`);
    }
  };

  const handleSave = async () => {
    if (!activeEntity || !hasCrudApi) return;

    try {
      setIsSaving(true);
      setModalError('');

      let parsed = {};
      try {
        parsed = JSON.parse(jsonInput || '{}');
      } catch (error) {
        throw new Error('JSON is invalid. Please fix and try again.');
      }

      const isEdit = modalMode === 'edit';
      const path = isEdit
        ? `/admin/entities/${activeEntity}/${editingId}`
        : `/admin/entities/${activeEntity}`;
      const method = isEdit ? 'PATCH' : 'POST';

      await fetchFromApi(path, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(parsed),
      });

      setModalOpen(false);
      await loadEntities(activeEntity, searchTerm);
      await loadSummary();
      await loadDashboardActivity();
    } catch (error) {
      setModalError(error.message || 'Save failed.');
    } finally {
      setIsSaving(false);
    }
  };

  const renderDashboard = () => (
    <>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        <StatCard title="Total Revenue" value={isStatsLoading ? '...' : formatCurrency(stats.totalRevenue)} color="border-blue-500" />
        <StatCard title="Active Users" value={isStatsLoading ? '...' : String(stats.activeUsers)} color="border-cyan-500" />
        <StatCard title="Active Repairmen" value={isStatsLoading ? '...' : String(stats.activeRepairmen)} color="border-orange-500" />
        <StatCard title="Pending Bookings" value={isStatsLoading ? '...' : String(stats.pendingBookings)} color="border-yellow-500" />
        <StatCard title="Completed Bookings" value={isStatsLoading ? '...' : String(stats.completedBookings)} color="border-green-500" />
        <StatCard title="Active Services" value={isStatsLoading ? '...' : String(stats.activeServices)} color="border-indigo-500" />
        <StatCard title="Average Rating" value={isStatsLoading ? '...' : `${stats.avgRating.toFixed(1)}/5`} color="border-emerald-500" />
      </div>

      {statsError ? <p className="text-sm text-red-500 mb-6">{statsError}</p> : null}

      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 mb-8">
        <h3 className="text-lg font-semibold text-gray-700 mb-4">System Totals</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {Object.entries(totals).map(([key, value]) => (
            <div key={key} className="p-4 rounded-xl bg-gray-50 border border-gray-100">
              <p className="text-xs uppercase tracking-wider text-gray-500">{key}</p>
              <p className="text-2xl font-bold text-gray-800">{value}</p>
            </div>
          ))}
        </div>
      </div>

      <EntityTable
        title="Recent System Activity"
        columns={columns}
        rows={activity}
        isLoading={isActivityLoading}
        error={activityError}
        showActions={false}
      />
    </>
  );

  const renderEntityPage = () => (
    <>
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-4 mb-6 flex flex-col md:flex-row gap-3 md:items-center md:justify-between">
        <div className="flex items-center gap-2 w-full md:max-w-md">
          <Search size={16} className="text-gray-400" />
          <input
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder={`Search ${activeTab}`}
            className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-blue-400"
          />
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => loadEntities(activeEntity, searchTerm)}
            className="px-4 py-2 rounded-lg border border-gray-200 text-sm text-gray-700 hover:bg-gray-50 flex items-center gap-2"
          >
            <RefreshCcw size={14} />
            Refresh
          </button>
          <button
            onClick={openCreateModal}
            disabled={!hasCrudApi}
            className="px-4 py-2 rounded-lg bg-blue-700 text-white text-sm hover:bg-blue-800 flex items-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed"
          >
            <Plus size={14} />
            {hasCrudApi ? 'Add New' : 'Add New (Unavailable)'}
          </button>
        </div>
      </div>

      <EntityTable
        title={`${activeTab} Data`}
        columns={columns}
        rows={tableItems}
        isLoading={isTableLoading}
        error={tableError}
        showActions={hasCrudApi}
        onEdit={openEditModal}
        onDelete={handleDelete}
      />
    </>
  );

  const renderVerificationPage = () => (
    <>
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-4 mb-6 flex items-center justify-between gap-3">
        <div>
          <h3 className="text-lg font-semibold text-gray-700">Repairman Verification Queue</h3>
          <p className="text-sm text-gray-500">
            Review submitted identity details, document links, selfie links, and approval status.
          </p>
        </div>
        <button
          onClick={loadVerifications}
          className="px-4 py-2 rounded-lg border border-gray-200 text-sm text-gray-700 hover:bg-gray-50 flex items-center gap-2"
        >
          <RefreshCcw size={14} />
          Refresh
        </button>
      </div>

      <div className="space-y-4">
        {isVerificationLoading ? (
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-10 text-center text-gray-400">
            Loading verification queue...
          </div>
        ) : verificationError ? (
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 text-red-500">
            {verificationError}
          </div>
        ) : verificationItems.length === 0 ? (
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-10 text-center text-gray-400">
            No verification submissions found.
          </div>
        ) : (
          verificationItems.map((item) => {
            const profile = item.verification_profile || {};
            const documents = item.verification_documents || {};
            const isBusy = Boolean(reviewState[item.id]);

            return (
              <div
                key={item.id}
                className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6"
              >
                <div className="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-4">
                  <div>
                    <div className="flex items-center gap-3 mb-2">
                      <h3 className="text-xl font-semibold text-gray-800">
                        {item.name || 'Repairman'}
                      </h3>
                      <span
                        className={`px-3 py-1 rounded-full text-xs font-semibold ${
                          item.status === 'verified'
                            ? 'bg-green-100 text-green-700'
                            : item.status === 'rejected'
                            ? 'bg-red-100 text-red-700'
                            : 'bg-orange-100 text-orange-700'
                        }`}
                      >
                        {String(item.status || 'unverified').replace(/_/g, ' ')}
                      </span>
                    </div>
                    <p className="text-sm text-gray-500">
                      {item.specialization || profile.specialization || 'General repair'}
                    </p>
                    <p className="text-sm text-gray-500">
                      {item.phone || profile.phone || 'No phone'} | {item.city || profile.city || 'No city'}
                    </p>
                    <p className="text-xs text-gray-400 mt-2">
                      Submitted: {item.submitted_at || 'Not submitted'}
                    </p>
                    {item.rejection_reason ? (
                      <p className="text-sm text-red-600 mt-2">
                        Rejection reason: {item.rejection_reason}
                      </p>
                    ) : null}
                  </div>

                  <div className="flex flex-wrap gap-2">
                    <button
                      onClick={() => handleReviewVerification(item.id, 'under_review')}
                      disabled={isBusy}
                      className="px-3 py-2 rounded-lg border border-amber-200 text-amber-700 hover:bg-amber-50 text-sm disabled:opacity-60"
                    >
                      {reviewState[item.id] === 'under_review' ? 'Saving...' : 'Mark Review'}
                    </button>
                    <button
                      onClick={() => handleReviewVerification(item.id, 'approve')}
                      disabled={isBusy}
                      className="px-3 py-2 rounded-lg border border-green-200 text-green-700 hover:bg-green-50 text-sm disabled:opacity-60"
                    >
                      {reviewState[item.id] === 'approve' ? 'Approving...' : 'Approve'}
                    </button>
                    <button
                      onClick={() => handleReviewVerification(item.id, 'reject')}
                      disabled={isBusy}
                      className="px-3 py-2 rounded-lg border border-red-200 text-red-700 hover:bg-red-50 text-sm disabled:opacity-60"
                    >
                      {reviewState[item.id] === 'reject' ? 'Rejecting...' : 'Reject'}
                    </button>
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-6">
                  <div className="rounded-xl bg-gray-50 border border-gray-100 p-4">
                    <h4 className="text-sm font-semibold text-gray-700 mb-3">Identity</h4>
                    <div className="space-y-2 text-sm text-gray-600">
                      <p>Full name: {profile.full_name || '-'}</p>
                      <p>DOB: {profile.date_of_birth || '-'}</p>
                      <p>ID type: {documents.id_type || '-'}</p>
                      <p>ID last 4: {documents.id_last4 || '-'}</p>
                      <p>DigiLocker ref: {documents.digilocker_reference || '-'}</p>
                    </div>
                  </div>

                  <div className="rounded-xl bg-gray-50 border border-gray-100 p-4">
                    <h4 className="text-sm font-semibold text-gray-700 mb-3">Work Details</h4>
                    <div className="space-y-2 text-sm text-gray-600">
                      <p>Specialization: {profile.specialization || '-'}</p>
                      <p>Experience: {normalizeDisplayValue(profile.experience_years)}</p>
                      <p>Address: {profile.address || '-'}</p>
                      <p>Notes: {profile.notes || '-'}</p>
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
                  <div className="rounded-xl bg-blue-50 border border-blue-100 p-4">
                    <h4 className="text-sm font-semibold text-blue-900 mb-3">Submitted Links</h4>
                    <div className="space-y-2 text-sm">
                      <p>
                        ID proof:{' '}
                        {documents.id_proof_url ? (
                          <a className="text-blue-700 underline break-all" href={documents.id_proof_url} target="_blank" rel="noreferrer">
                            {documents.id_proof_url}
                          </a>
                        ) : '-'}
                      </p>
                      <p>
                        Address proof:{' '}
                        {documents.address_proof_url ? (
                          <a className="text-blue-700 underline break-all" href={documents.address_proof_url} target="_blank" rel="noreferrer">
                            {documents.address_proof_url}
                          </a>
                        ) : '-'}
                      </p>
                      <p>
                        Skill certificate:{' '}
                        {documents.skill_certificate_url ? (
                          <a className="text-blue-700 underline break-all" href={documents.skill_certificate_url} target="_blank" rel="noreferrer">
                            {documents.skill_certificate_url}
                          </a>
                        ) : '-'}
                      </p>
                      <p>
                        Selfie:{' '}
                        {documents.selfie_url ? (
                          <a className="text-blue-700 underline break-all" href={documents.selfie_url} target="_blank" rel="noreferrer">
                            {documents.selfie_url}
                          </a>
                        ) : '-'}
                      </p>
                    </div>
                  </div>

                  <div className="rounded-xl bg-gray-50 border border-gray-100 p-4">
                    <h4 className="text-sm font-semibold text-gray-700 mb-3">Review Notes</h4>
                    <div className="space-y-2 text-sm text-gray-600">
                      <p>Reviewed at: {item.reviewed_at || '-'}</p>
                      <p>Current status: {item.status || '-'}</p>
                      <p>Verified: {item.is_verified ? 'Yes' : 'No'}</p>
                      <p>Rejection reason: {item.rejection_reason || '-'}</p>
                    </div>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>
    </>
  );

  return (
    <div className="flex h-screen bg-gray-50 font-sans">
      <aside className={`${isSidebarOpen ? 'w-64' : 'w-20'} bg-[#1e3a8a] text-white transition-all duration-300 flex flex-col`}>
        <div className="p-6 flex items-center gap-3">
          <img
            src="/logo.jpg"
            alt="QuickFix logo"
            className="h-10 w-10 rounded-lg object-cover border border-white/20 bg-white"
          />
          {isSidebarOpen && <span className="text-xl font-bold tracking-tight">QuickFix</span>}
        </div>

        <nav className="flex-1 px-4 space-y-2 overflow-y-auto pb-4">
          {MENU_ITEMS.map((item) => (
            <button
              key={item.name}
              onClick={() => setActiveTab(item.name)}
              className={`w-full flex items-center gap-4 px-4 py-3 rounded-xl transition-colors ${
                activeTab === item.name ? 'bg-orange-500 text-white' : 'hover:bg-blue-800 text-blue-100'
              }`}
            >
              {item.icon}
              {isSidebarOpen && <span className="font-medium">{item.name}</span>}
            </button>
          ))}
        </nav>

        <div className="p-4 border-t border-blue-800">
          <button className="flex items-center gap-4 px-4 py-3 text-red-300 hover:text-red-100 w-full transition-colors">
            <LogOut size={20} />
            {isSidebarOpen && <span className="font-medium">Logout</span>}
          </button>
        </div>
      </aside>

      <main className="flex-1 flex flex-col overflow-hidden">
        <header className="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-8">
          <button onClick={() => setIsSidebarOpen(!isSidebarOpen)} className="text-gray-500 hover:text-blue-900">
            {isSidebarOpen ? <X /> : <Menu />}
          </button>
          <div className="flex items-center gap-4">
            <div className="text-right">
              <p className="text-sm font-semibold text-gray-700">Admin Control Center</p>
              <p className="text-xs text-green-500 font-medium">Online</p>
            </div>
            <img
              src="/logo.jpg"
              alt="QuickFix logo"
              className="w-10 h-10 rounded-full object-cover border-2 border-orange-500 bg-white"
            />
          </div>
        </header>

        <div className="p-8 overflow-y-auto">
          <h1 className="text-2xl font-bold text-gray-800 mb-6">{activeTab}</h1>
          {activeTab === 'Dashboard'
            ? renderDashboard()
            : activeTab === 'Verification'
            ? renderVerificationPage()
            : renderEntityPage()}
        </div>
      </main>

      {modalOpen ? (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-xl border border-gray-100 w-full max-w-3xl">
            <div className="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-800">{modalTitle}</h3>
              <button onClick={() => setModalOpen(false)} className="text-gray-400 hover:text-gray-600">
                <X size={18} />
              </button>
            </div>
            <div className="p-6">
              <p className="text-xs text-gray-500 mb-2">
                Use JSON payload. This directly writes to Firestore for admin-level control.
              </p>
              {ENTITY_HELP_TEXT[activeEntity] ? (
                <p className="text-xs text-blue-600 mb-3">{ENTITY_HELP_TEXT[activeEntity]}</p>
              ) : null}
              <textarea
                value={jsonInput}
                onChange={(e) => setJsonInput(e.target.value)}
                className="w-full h-80 border border-gray-200 rounded-xl p-3 font-mono text-sm focus:outline-none focus:border-blue-400"
              />
              {modalError ? <p className="text-sm text-red-500 mt-3">{modalError}</p> : null}
            </div>
            <div className="px-6 py-4 border-t border-gray-100 flex justify-end gap-2">
              <button
                onClick={() => setModalOpen(false)}
                className="px-4 py-2 rounded-lg border border-gray-200 text-sm text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleSave}
                disabled={isSaving}
                className="px-4 py-2 rounded-lg bg-blue-700 text-white text-sm hover:bg-blue-800 disabled:opacity-60"
              >
                {isSaving ? 'Saving...' : 'Save'}
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
};

const StatCard = ({ title, value, color }) => (
  <div className={`bg-white p-6 rounded-2xl shadow-sm border-l-4 ${color}`}>
    <p className="text-sm text-gray-500 font-medium uppercase tracking-wider">{title}</p>
    <div className="flex items-end justify-between mt-2">
      <h2 className="text-3xl font-bold text-gray-800">{value}</h2>
    </div>
  </div>
);

const EntityTable = ({ title, columns, rows, isLoading, error, showActions, onEdit, onDelete }) => (
  <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
    <h3 className="text-lg font-semibold text-gray-700 mb-4">{title}</h3>
    <div className="h-[28rem] border-2 border-dashed border-gray-200 rounded-xl overflow-auto">
      {isLoading ? (
        <div className="h-full flex items-center justify-center text-gray-400">Loading...</div>
      ) : error ? (
        <div className="h-full flex items-center justify-center text-red-400 px-4 text-center">{error}</div>
      ) : rows.length === 0 ? (
        <div className="h-full flex items-center justify-center text-gray-400">No records found.</div>
      ) : (
        <table className="w-full text-sm">
          <thead className="sticky top-0 bg-gray-50 border-b border-gray-200">
            <tr>
              {columns.map((column) => (
                <th key={column} className="text-left px-4 py-3 text-gray-600 font-semibold whitespace-nowrap">
                  {column}
                </th>
              ))}
              {showActions ? <th className="text-left px-4 py-3 text-gray-600 font-semibold">Actions</th> : null}
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.id} className="border-b border-gray-100 last:border-0">
                {columns.map((column) => (
                  <td key={`${row.id}-${column}`} className="px-4 py-3 text-gray-700 align-top max-w-xs">
                    <div className="truncate" title={normalizeDisplayValue(row[column])}>
                      {normalizeDisplayValue(row[column])}
                    </div>
                  </td>
                ))}
                {showActions ? (
                  <td className="px-4 py-3 whitespace-nowrap">
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => onEdit(row)}
                        className="px-2 py-1 rounded border border-blue-200 text-blue-700 hover:bg-blue-50 text-xs flex items-center gap-1"
                      >
                        <Pencil size={12} />
                        Edit
                      </button>
                      <button
                        onClick={() => onDelete(row.id)}
                        className="px-2 py-1 rounded border border-red-200 text-red-700 hover:bg-red-50 text-xs flex items-center gap-1"
                      >
                        <Trash2 size={12} />
                        Delete
                      </button>
                    </div>
                  </td>
                ) : null}
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  </div>
);

export default Dashboard;
