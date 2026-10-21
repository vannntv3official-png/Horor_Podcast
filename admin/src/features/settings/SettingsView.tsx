import React, { useState } from 'react';
import { ShieldCheck, HardDrive, Globe, Save } from 'lucide-react';

export const SettingsView: React.FC = () => {
  const [appName, setAppName] = useState('Khmer Horror Podcast');
  const [maxUploadMb, setMaxUploadMb] = useState('50');
  const [defaultLanguage, setDefaultLanguage] = useState('km');
  const [privacyUrl, setPrivacyUrl] = useState('https://khmerhorrorpodcast.com/privacy');
  const [termsUrl, setTermsUrl] = useState('https://khmerhorrorpodcast.com/terms');
  const [saved, setSaved] = useState(false);

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  return (
    <div className="max-w-3xl space-y-6">
      <div>
        <h2 className="text-base font-bold text-[#1D102F]">ការកំណត់ប្រព័ន្ធ (System Settings)</h2>
        <p className="text-xs text-[#635C6E]">កំណត់គោលការណ៍ផ្ទុកទិន្នន័យ ដែនកំណត់ឯកសារ និងព័ត៌មានទូទៅនៃកម្មវិធី</p>
      </div>

      {saved && (
        <div className="p-4 rounded-2xl bg-emerald-50 border border-emerald-200 text-xs font-semibold text-emerald-800 flex items-center gap-2">
          <ShieldCheck className="w-4 h-4 text-emerald-600" />
          <span>ការកំណត់ត្រូវបានរក្សាទុកដោយជោគជ័យ!</span>
        </div>
      )}

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
            <h3 className="font-bold text-sm text-[#1D102F]">Storage & Download Policy</h3>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-[#1D102F] mb-1">ទំហំឯកសារ MP3 អតិបរមា (Max Upload Size MB)</label>
              <input
                type="number"
                value={maxUploadMb}
                onChange={(e) => setMaxUploadMb(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-xs text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
              />
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
