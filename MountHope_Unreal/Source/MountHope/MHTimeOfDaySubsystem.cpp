#include "MHTimeOfDaySubsystem.h"

void UMHTimeOfDaySubsystem::AdvanceTime(float DeltaSeconds)
{
    if (RealSecondsPerGameDay <= 0.0f)
    {
        return;
    }

    CurrentHour += (DeltaSeconds / RealSecondsPerGameDay) * 24.0f;
    while (CurrentHour >= 24.0f)
    {
        CurrentHour -= 24.0f;
    }

    const int32 WholeHour = FMath::FloorToInt(CurrentHour);
    if (WholeHour != LastBroadcastHour)
    {
        LastBroadcastHour = WholeHour;
        OnHourChanged.Broadcast(WholeHour);
    }
}

float UMHTimeOfDaySubsystem::GetSunIntensityMultiplier() const
{
    const float NightFloor = 0.15f;

    if (CurrentHour >= 8.0f && CurrentHour < 17.0f)
    {
        return 1.0f;
    }
    if (CurrentHour >= 6.0f && CurrentHour < 8.0f)
    {
        return FMath::Lerp(NightFloor, 1.0f, (CurrentHour - 6.0f) / 2.0f);
    }
    if (CurrentHour >= 17.0f && CurrentHour < 19.0f)
    {
        return FMath::Lerp(1.0f, NightFloor, (CurrentHour - 17.0f) / 2.0f);
    }
    return NightFloor;
}
