#include "MHVehiclePawn.h"

AMHVehiclePawn::AMHVehiclePawn()
{
    PrimaryActorTick.bCanEverTick = true;
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
