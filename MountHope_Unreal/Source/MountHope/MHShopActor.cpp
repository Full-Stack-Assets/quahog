#include "MHShopActor.h"

#include "Components/SphereComponent.h"
#include "EngineUtils.h"
#include "Kismet/GameplayStatics.h"
#include "MHGameStateSubsystem.h"
#include "MHReputationSubsystem.h"
#include "MHVehiclePawn.h"

AMHShopActor::AMHShopActor()
{
    PrimaryActorTick.bCanEverTick = false;

    InteractionSphere = CreateDefaultSubobject<USphereComponent>(TEXT("InteractionSphere"));
    RootComponent = InteractionSphere;
    InteractionSphere->SetSphereRadius(InteractionRadius);
    InteractionSphere->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    InteractionSphere->SetCollisionResponseToAllChannels(ECR_Ignore);
    InteractionSphere->SetCollisionResponseToChannel(ECC_Pawn, ECR_Overlap);
}

void AMHShopActor::BeginPlay()
{
    Super::BeginPlay();
    InteractionSphere->SetSphereRadius(InteractionRadius);
}

FText AMHShopActor::GetInteractionPrompt_Implementation() const
{
    if (ShopType == EMHShopType::Garage)
    {
        return FText::FromString(FString::Printf(TEXT("Repair vehicle at %s ($%d)"), *ShopName, GetEffectiveRepairCost()));
    }

    return FText::FromString(FString::Printf(TEXT("Shop at %s"), *ShopName));
}

void AMHShopActor::Interact_Implementation(APawn* InstigatorPawn)
{
    if (!InstigatorPawn)
    {
        return;
    }

    switch (ShopType)
    {
    case EMHShopType::Garage:
        HandleGarageInteraction(InstigatorPawn);
        break;
    case EMHShopType::GeneralStore:
        HandleGeneralStoreInteraction(InstigatorPawn);
        break;
    default:
        break;
    }
}

void AMHShopActor::HandleGarageInteraction(APawn* InstigatorPawn)
{
    UGameInstance* GameInstance = GetGameInstance();
    if (!GameInstance)
    {
        return;
    }

    AMHVehiclePawn* Vehicle = FindNearestDamagedVehicle(InstigatorPawn);
    if (!Vehicle)
    {
        UE_LOG(LogTemp, Log, TEXT("MountHope: No damaged vehicle nearby for %s"), *ShopName);
        return;
    }

    UMHGameStateSubsystem* GameState = GameInstance->GetSubsystem<UMHGameStateSubsystem>();
    if (!GameState)
    {
        return;
    }

    const int32 Cost = GetEffectiveRepairCost();
    if (GameState->Cash < Cost)
    {
        UE_LOG(LogTemp, Log, TEXT("MountHope: Not enough cash to repair at %s (need $%d)"), *ShopName, Cost);
        UGameplayStatics::PlaySound2D(this, TransactionDeniedSound);
        return;
    }

    GameState->AddCash(-Cost);
    Vehicle->RepairVehicle();
    UE_LOG(LogTemp, Log, TEXT("MountHope: Repaired vehicle at %s for $%d"), *ShopName, Cost);
    UGameplayStatics::PlaySound2D(this, TransactionSuccessSound);
}

void AMHShopActor::HandleGeneralStoreInteraction(APawn* InstigatorPawn)
{
    UGameInstance* GameInstance = GetGameInstance();
    if (!GameInstance || LinkedBusinessId.IsEmpty())
    {
        return;
    }

    if (UMHGameStateSubsystem* GameState = GameInstance->GetSubsystem<UMHGameStateSubsystem>())
    {
        if (GameState->BuyBusiness(LinkedBusinessId))
        {
            UE_LOG(LogTemp, Log, TEXT("MountHope: Purchased business '%s' at %s"), *LinkedBusinessId, *ShopName);
            UGameplayStatics::PlaySound2D(this, TransactionSuccessSound);
        }
        else
        {
            UE_LOG(LogTemp, Log, TEXT("MountHope: Could not purchase '%s' at %s"), *LinkedBusinessId, *ShopName);
            UGameplayStatics::PlaySound2D(this, TransactionDeniedSound);
        }
    }
}

int32 AMHShopActor::GetEffectiveRepairCost() const
{
    if (!ReputationFactionTag.IsValid())
    {
        return BaseRepairCost;
    }

    UGameInstance* GameInstance = GetGameInstance();
    if (!GameInstance)
    {
        return BaseRepairCost;
    }

    UMHReputationSubsystem* Reputation = GameInstance->GetSubsystem<UMHReputationSubsystem>();
    if (Reputation && Reputation->MeetsReputation(ReputationFactionTag, ReputationDiscountThreshold))
    {
        return FMath::Max(0, FMath::RoundToInt(BaseRepairCost * (1.0f - ReputationDiscountPct)));
    }

    return BaseRepairCost;
}

AMHVehiclePawn* AMHShopActor::FindNearestDamagedVehicle(const APawn* InstigatorPawn) const
{
    if (!GetWorld())
    {
        return nullptr;
    }

    const FVector SearchOrigin = InstigatorPawn ? InstigatorPawn->GetActorLocation() : GetActorLocation();
    AMHVehiclePawn* BestVehicle = nullptr;
    float BestDistSq = VehicleServiceRange * VehicleServiceRange;

    for (TActorIterator<AMHVehiclePawn> It(GetWorld()); It; ++It)
    {
        AMHVehiclePawn* Candidate = *It;
        if (!IsValid(Candidate) || Candidate->GetHealthPercent() >= 1.0f)
        {
            continue;
        }

        const float DistSq = FVector::DistSquared(SearchOrigin, Candidate->GetActorLocation());
        if (DistSq <= BestDistSq)
        {
            BestDistSq = DistSq;
            BestVehicle = Candidate;
        }
    }

    return BestVehicle;
}
