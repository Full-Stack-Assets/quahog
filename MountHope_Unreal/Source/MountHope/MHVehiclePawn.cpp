#include "MHVehiclePawn.h"

AMHVehiclePawn::AMHVehiclePawn()
{
    PrimaryActorTick.bCanEverTick = false;
}

bool AMHVehiclePawn::CanDriverEnter(const APawn* CandidateDriver) const
{
    if (CandidateDriver == nullptr)
    {
        return false;
    }

    const float EntryRadiusUnrealUnits = EntryRadiusMeters * 100.0f;
    return FVector::DistSquared(CandidateDriver->GetActorLocation(), GetActorLocation()) <= FMath::Square(EntryRadiusUnrealUnits);
}

FVector AMHVehiclePawn::GetSuggestedExitLocation() const
{
    return GetActorLocation() + (GetActorRightVector() * 175.0f) + FVector(0.0f, 0.0f, 20.0f);
}
