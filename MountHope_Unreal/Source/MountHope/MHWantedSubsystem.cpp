#include "MHWantedSubsystem.h"

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

    Heat = FMath::Clamp(Heat + Severity * Multiplier, 0, 100);
    RecalculateWantedLevel();
}

void UMHWantedSubsystem::ReduceHeat(int32 Amount)
{
    if (Amount <= 0)
    {
        return;
    }

    Heat = FMath::Clamp(Heat - Amount, 0, 100);
    RecalculateWantedLevel();
}

void UMHWantedSubsystem::ClearWantedState()
{
    Heat = 0;
    WantedLevel = 0;
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
