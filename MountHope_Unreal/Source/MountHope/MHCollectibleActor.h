#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "MHInteractable.h"
#include "MHCollectibleActor.generated.h"

class USphereComponent;
class UStaticMeshComponent;

UCLASS(BlueprintType)
class MOUNTHOPE_API AMHCollectibleActor : public AActor, public IMHInteractable
{
    GENERATED_BODY()

public:
    AMHCollectibleActor();

    virtual FText GetInteractionPrompt_Implementation() const override;
    virtual void Interact_Implementation(APawn* InstigatorPawn) override;

protected:
    virtual void BeginPlay() override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mount Hope|Collectible")
    TObjectPtr<USphereComponent> InteractionSphere;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mount Hope|Collectible")
    TObjectPtr<UStaticMeshComponent> DisplayMesh;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Collectible")
    FName ItemId = NAME_None;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Collectible")
    float InteractionRadius = 200.0f;

private:
    void RefreshVisibilityForCollectedState();
};
