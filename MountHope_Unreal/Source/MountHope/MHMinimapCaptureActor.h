#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "MHMinimapCaptureActor.generated.h"

class USceneCaptureComponent2D;
class UTextureRenderTarget2D;

UCLASS(BlueprintType)
class MOUNTHOPE_API AMHMinimapCaptureActor : public AActor
{
    GENERATED_BODY()

public:
    AMHMinimapCaptureActor();

    virtual void Tick(float DeltaSeconds) override;

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Minimap")
    UTextureRenderTarget2D* GetRenderTarget() const { return RenderTarget; }

protected:
    virtual void BeginPlay() override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mount Hope|Minimap")
    TObjectPtr<USceneCaptureComponent2D> CaptureComponent;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Minimap")
    int32 RenderTargetSize = 512;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Minimap")
    float CaptureHeightAboveGround = 4000.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Minimap")
    float OrthoWidth = 6000.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Minimap")
    bool bFollowPlayerYaw = true;

private:
    UPROPERTY(Transient)
    TObjectPtr<UTextureRenderTarget2D> RenderTarget;

    void CreateRenderTarget();
};
