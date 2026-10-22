import React, { useState, useEffect } from 'react';
import {
  ShieldCheck,
  HardDrive,
  Globe,
  Save,
  CheckCircle2,
  XCircle,
  RefreshCw,
  Server,
  AlertTriangle,
} from 'lucide-react';
import {
  isConfigured,
  supabaseProjectUrl,
  testConnection,
  checkStorageBuckets,
  BUCKETS,
} from '../../lib/supabase';

export const SettingsView: React.FC = () => {
  const [appName, setAppName] = useState('Khmer Horror Podcast');
  const [maxUploadMb, setMaxUploadMb] = useState('50');
  const [defaultLanguage, setDefaultLanguage] = useState('km');
  const [privacyUrl, setPrivacyUrl] = useState('https://khmerhorrorpodcast.com/privacy');
  const [termsUrl, setTermsUrl] = useState('https://khmerhorrorpodcast.com/terms');
  const [saved, setSaved] = useState(false);

  // Diagnostics State
  const [testingPing, setTestingPing] = useState(false);
  const [pingResult, setPingResult] = useState<{ ok: boolean; latencyMs: number; error?: string } | null>(null);
  const [bucketStatus, setBucketStatus] = useState<Record<string, boolean>>({});

  const runDiagnostics = async () => {
    setTestingPing(true);
    try {
      const ping = await testConnection();
      setPingResult(ping);

      const buckets = await checkStorageBuckets();
      setBucketStatus(buckets);
    } catch (err: unknown) {
      setPingResult({ ok: false, latencyMs: 0, error: (err as Error).message });
    } finally {
      setTestingPing(false);
    }
  };

  useEffect(() => {
    runDiagnostics();
  }, []);

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  // Mask Supabase URL for clean presentation
  const maskedUrl = supabaseProjectUrl.replace(/^(https?:\/\/)(.{4}).*(.{6})(\.supabase\.co.*)$/, '$1$2••••$3$4');

  return (
    <div className="max-w-4xl space-y-6">
      <div>
        <h2 className="text-base font-bold text-[#1D102F]">ការកំណត់ប្រព័ន្ធ (System Settings & Diagnostics)</h2>
        <p className="text-xs text-[#635C6E]">
          ត្រួតពិនិត្យដំណើរការតភ្ជាប់ Supabase Cloud, Storage Buckets និងកំណត់គោលការណ៍ទូទៅនៃកម្មវិធី
        </p>
      </div>

      {saved && (
        <div className="p-4 rounded-2xl bg-emerald-50 border border-emerald-200 text-xs font-semibold text-emerald-800 flex items-center gap-2">
          <ShieldCheck className="w-4 h-4 text-emerald-600" />
          <span>ការកំណត់ត្រូវបានរក្សាទុកដោយជោគជ័យ!</span>
        </div>
      )}

      {/* Cloud & Vercel Diagnostics Card */}
      <div className="glass-panel p-6 rounded-3xl border border-[#E2DCEB] space-y-4">
        <div className="flex items-center justify-between pb-3 border-b border-[#E2DCEB]">
          <div className="flex items-center gap-2">
            <Server className="w-4 h-4 text-[#C89B3C]" />
            <h3 className="font-bold text-sm text-[#1D102F]">Supabase & Vercel Diagnostics</h3>
          </div>
          <button
            type="button"
            onClick={runDiagnostics}
            disabled={testingPing}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white border border-[#E2DCEB] text-xs font-semibold text-[#1D102F] hover:bg-gray-50 transition-colors cursor-pointer disabled:opacity-50"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${testingPing ? 'animate-spin text-[#C89B3C]' : 'text-[#8A7B9B]'}`} />
            <span>តេស្តការតភ្ជាប់ (Test Ping)</span>
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* Connection Status */}
          <div className="p-4 rounded-2xl bg-white/70 border border-[#E2DCEB] space-y-2">
            <div className="flex items-center justify-between text-xs">
              <span className="font-semibold text-[#635C6E]">ស្ថានភាពតភ្ជាប់ (Database):</span>
              {testingPing ? (
                <span className="text-[#8A7B9B] font-mono text-[11px]">Testing...</span>
              ) : pingResult?.ok ? (
                <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-emerald-100 text-emerald-800 font-bold text-[10px]">
                  <CheckCircle2 className="w-3 h-3" /> Online ({pingResult.latencyMs}ms)
                </span>
              ) : (
                <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-rose-100 text-rose-800 font-bold text-[10px]">
                  <XCircle className="w-3 h-3" /> Error / Offline
                </span>
              )}
            </div>

            <div className="flex items-center justify-between text-xs">
              <span className="font-semibold text-[#635C6E]">Project Endpoint:</span>
              <span className="font-mono text-[11px] text-[#1D102F] truncate max-w-[200px]">
                {maskedUrl}
              </span>
            </div>

            <div className="flex items-center justify-between text-xs">
              <span className="font-semibold text-[#635C6E]">Env Configuration:</span>
              <span
                className={`font-semibold text-[11px] ${
                  isConfigured ? 'text-emerald-700' : 'text-amber-700'
                }`}
              >
                {isConfigured ? 'Valid Credentials' : 'Demo / Placeholder'}
              </span>
            </div>
          </div>

          {/* Storage Buckets Status */}
          <div className="p-4 rounded-2xl bg-white/70 border border-[#E2DCEB] space-y-2">
            <span className="block text-xs font-semibold text-[#635C6E] mb-1">
              Storage Buckets Accessibility:
            </span>
            <div className="space-y-1.5 text-xs">
              {Object.entries(BUCKETS).map(([key, bucketName]) => {
                const accessible = bucketStatus[bucketName];
                return (
                  <div key={key} className="flex items-center justify-between font-mono text-[11px]">
                    <span className="text-[#1D102F]">{bucketName}</span>
                    {testingPing ? (
                      <span className="text-[#8A7B9B]">checking...</span>
                    ) : accessible ? (
                      <span className="text-emerald-600 font-bold flex items-center gap-1">
                        <CheckCircle2 className="w-3 h-3" /> Accessible
                      </span>
                    ) : (
                      <span className="text-amber-600 font-bold flex items-center gap-1">
                        <AlertTriangle className="w-3 h-3" /> Check Policies
                      </span>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        {/* Vercel Deploy Helper Notice */}
        {!isConfigured && (
          <div className="p-4 rounded-2xl bg-amber-50 border border-amber-300 text-xs text-amber-900 flex items-start gap-3">
            <AlertTriangle className="w-5 h-5 flex-shrink-0 text-amber-600 mt-0.5" />
            <div className="space-y-1">
              <p className="font-bold text-amber-950">គន្លឹះដោះស្រាយពេល Deploy លើ Vercel:</p>
              <p>
                ប្រសិនបើមិនអាច Login ឬដំណើរការទិន្នន័យលើ Vercel សូមចូលទៅកាន់ <strong>Vercel Dashboard &gt; Settings &gt; Environment Variables</strong> រួចបន្ថែម:
              </p>
              <ul className="list-disc list-inside font-mono text-[11px] space-y-0.5 text-amber-950 mt-1">
                <li>VITE_SUPABASE_URL = &lt;Your Supabase Project URL&gt;</li>
                <li>VITE_SUPABASE_ANON_KEY = &lt;Your Supabase Anon Public Key&gt;</li>
              </ul>
              <p className="mt-1">បន្ទាប់មកចុច <strong>Redeploy</strong> ដើម្បីឱ្យ Vercel build ជាមួយ environment variables ថ្មី។</p>
            </div>
          </div>
        )}
      </div>

      <form onSubmit={handleSave} className="space-y-6">
        {/* App Branding */}
        <div className="glass-panel p-6 rounded-3xl border border-[#E2DCEB] space-y-4">
          <div className="flex items-center gap-2 pb-3 border-b border-[#E2DCEB]">
            <Globe className="w-4 h-4 text-[#C89B3C]" />
            <h3 className="font-bold text-sm text-[#1D102F]">App Identity & Localization</h3>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-[#1D102F] mb-1">ឈ្មោះកម្មវិធី (Application Name)</label>
              <input
                type="text"
                value={appName}
                onChange={(e) => setAppName(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-xs text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#1D102F] mb-1">ភាសាលំនាំដើម (Default Language)</label>
              <select
                value={defaultLanguage}
                onChange={(e) => setDefaultLanguage(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-xs text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
              >
                <option value="km">ភាសាខ្មែរ (Khmer - km)</option>
                <option value="en">English (en)</option>
              </select>
            </div>
          </div>
        </div>

        {/* Storage Limits */}
        <div className="glass-panel p-6 rounded-3xl border border-[#E2DCEB] space-y-4">
          <div className="flex items-center gap-2 pb-3 border-b border-[#E2DCEB]">
            <HardDrive className="w-4 h-4 text-[#C89B3C]" />
            <h3 className="font-bold text-sm text-[#1D102F]">Storage & Upload Limits</h3>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-[#1D102F] mb-1">
                ទំហំឯកសារ MP3 អតិបរមា (Max Upload Size MB)
              </label>
              <input
                type="number"
                value={maxUploadMb}
                onChange={(e) => setMaxUploadMb(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-xs text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
              />
              <p className="text-[10px] text-[#8A7B9B] mt-1">Supabase Free Tier កំណត់ទំហំ 50MB ក្នុងមួយឯកសារ</p>
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#1D102F] mb-1">ប្រភេទសំឡេងអនុញ្ញាត (Supported Audio)</label>
              <input
                type="text"
                disabled
                value="audio/mpeg, audio/mp3, audio/m4a"
                className="w-full px-3.5 py-2.5 rounded-xl bg-gray-50 border border-[#E2DCEB] text-xs text-[#635C6E]"
              />
            </div>
          </div>
        </div>

        {/* Legal URLs */}
        <div className="glass-panel p-6 rounded-3xl border border-[#E2DCEB] space-y-4">
          <div className="flex items-center gap-2 pb-3 border-b border-[#E2DCEB]">
            <ShieldCheck className="w-4 h-4 text-[#C89B3C]" />
            <h3 className="font-bold text-sm text-[#1D102F]">Legal & Compliance Links</h3>
          </div>

          <div className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-[#1D102F] mb-1">Privacy Policy URL</label>
              <input
                type="url"
                value={privacyUrl}
                onChange={(e) => setPrivacyUrl(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-xs text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#1D102F] mb-1">Terms of Service URL</label>
              <input
                type="url"
                value={termsUrl}
                onChange={(e) => setTermsUrl(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-xs text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
              />
            </div>
          </div>
        </div>

        <button
          type="submit"
          className="flex items-center gap-2 px-6 py-3 rounded-xl bg-[#1D102F] hover:bg-[#2E1A47] text-white text-xs font-semibold shadow-md transition-all cursor-pointer"
        >
          <Save className="w-4 h-4 text-[#C89B3C]" />
          <span>រក្សាទុកការកំណត់ (Save Settings)</span>
        </button>
      </form>
    </div>
  );
};
