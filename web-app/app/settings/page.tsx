import { Navigation } from "@/components/navigation"
import { ThemeToggle } from "@/components/theme-toggle"

export default function SettingsPage() {
  return (
    <div className="min-h-screen">
      <Navigation />
      <main className="container mx-auto px-4 py-8">
        <h1 className="text-3xl font-bold mb-6">Settings</h1>
        <div className="space-y-6">
          <div className="flex items-center justify-between p-4 border rounded-lg">
            <div>
              <h3 className="font-medium">Appearance</h3>
              <p className="text-sm text-muted-foreground">Toggle light/dark mode</p>
            </div>
            <ThemeToggle />
          </div>
          {/* TODO: Additional settings */}
        </div>
      </main>
    </div>
  )
}
