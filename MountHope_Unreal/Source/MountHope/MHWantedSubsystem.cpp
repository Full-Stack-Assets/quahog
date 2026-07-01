#include "MHWantedSubsystem.h"

#include "Kismet/GameplayStatics.h"

void UMHWantedSubsystem::ReportCrime(EMHCrimeType CrimeType, int32 Severity)
{
    if (Severity <= 0)
    {
        return;
    }

    int32 Multiplier = 1;
    switch (CrimeType)
    {
    case EMHCrimeType::TrafficViolation:
        Multiplier = 1;
        break;
    case EMHCrimeType::Theft:
        Multiplier = 2;
        break;
    case EMHCrimeType::Assault:
        Multiplier = 4;
        break;
    case EMHCrimeType::PropertyDamage:
        Multiplier = 2;
        break;
    case EMHCrimeType::MissionHeat:
        Multiplier = 3;
        break;
    default:
        Multiplier = 1;
        break;
    }

    const int32 PreviousLevel = WantedLevel;
    Heat = FMath::Clamp(Heat + Severity * Multiplier, 0, 100);
    SecondsSinceLastCrime = 0.0f;
    RecalculateWantedLevel();

    if (WantedLevel != PreviousLevel)
    {
        OnWantedLevelChanged.Broadcast(WantedLevel);
        if (WantedLevel > PreviousLevel)
        {
            UGameplayStatics::PlaySound2D(this, WantedIncreaseSound);
        }
    }
}

void UMHWantedSubsystem::ReduceHeat(int32 Amount)
{
    if (Amount <= 0)
    {
        return;
    }

    const int32 PreviousLevel = WantedLevel;
    Heat = FMath::Clamp(Heat - Amount, 0, 100);
    RecalculateWantedLevel();

    if (WantedLevel != PreviousLevel)
    {
        OnWantedLevelChanged.Broadcast(WantedLevel);
    }
}

void UMHWantedSubsystem::ClearWantedState()
{
    const int32 PreviousLevel = WantedLevel;
    Heat = 0;
    WantedLevel = 0;
    SecondsSinceLastCrime = 0.0f;

    if (WantedLevel != PreviousLevel)
    {
        OnWantedLevelChanged.Broadcast(WantedLevel);
    }
}

void UMHWantedSubsystem::TickWantedDecay(float DeltaSeconds)
{
    if (Heat <= 0)
    {
        return;
    }

    SecondsSinceLastCrime += DeltaSeconds;
    if (SecondsSinceLastCrime < DecayDelaySeconds)
    {
        return;
    }

    const int32 PreviousLevel = WantedLevel;
    Heat = FMath::Clamp(Heat - FMath::RoundToInt(DecayPerSecond * DeltaSeconds), 0, 100);
    RecalculateWantedLevel();

    if (WantedLevel != PreviousLevel)
    {
        OnWantedLevelChanged.Broadcast(WantedLevel);
    }
}

int32 UMHWantedSubsystem::GetWantedLevel() const
{
    return WantedLevel;
}

bool UMHWantedSubsystem::IsPoliceSearching() const
{
    return WantedLevel > 0;
}

int32 UMHWantedSubsystem::GetSuggestedFine() const
{
    return WantedLevel * 75 + Heat * 5;
}

void UMHWantedSubsystem::RecalculateWantedLevel()
{
    WantedLevel = FMath::Clamp(FMath::DivideAndRoundUp(Heat, 20), 0, 5);
}
