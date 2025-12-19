"use client"

// TODO: Replace with real data fetching
const MOCK_DATA = Array.from({ length: 90 }, (_, i) => ({
  date: new Date(Date.now() - (89 - i) * 24 * 60 * 60 * 1000),
  count: Math.floor(Math.random() * 4), // 0-3 habits completed
}))

export function HeatmapGrid() {
  // TODO: Calculate intensity based on actual habit completion
  const getIntensity = (count: number) => {
    if (count === 0) return "bg-muted"
    if (count === 1) return "bg-green-200 dark:bg-green-900"
    if (count === 2) return "bg-green-400 dark:bg-green-700"
    return "bg-green-600 dark:bg-green-500"
  }

  return (
    <div className="space-y-4">
      {/* TODO: Time range selector (Week/Month/Quarter/Year) */}
      
      <div className="grid grid-cols-[repeat(auto-fill,minmax(12px,1fr))] gap-1 max-w-4xl">
        {MOCK_DATA.map((day, index) => (
          <div
            key={index}
            className={`aspect-square rounded-sm ${getIntensity(day.count)}`}
            title={`${day.date.toLocaleDateString()}: ${day.count} habits`}
          >
            {/* TODO: Tooltip on hover */}
          </div>
        ))}
      </div>

      {/* TODO: Score display (daily/weekly/monthly/yearly) */}
      <div className="flex gap-4 text-sm">
        <div>
          <span className="text-muted-foreground">Daily: </span>
          <span className="font-medium">0</span>
        </div>
        <div>
          <span className="text-muted-foreground">Weekly: </span>
          <span className="font-medium">0</span>
        </div>
        <div>
          <span className="text-muted-foreground">Monthly: </span>
          <span className="font-medium">0</span>
        </div>
      </div>
    </div>
  )
}
