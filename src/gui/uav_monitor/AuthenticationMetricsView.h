#pragma once

#include "metrics/AuthenticationMetrics.h"

#include <QtGlobal>

#include <functional>
#include <vector>

class QLabel;
class QLineSeries;
class QString;
class QValueAxis;
class QWidget;

/** @brief 共同维护无人机计算开销和估算能耗两个关联图表页面。 */
class AuthenticationMetricsView final
{
public:
    AuthenticationMetricsView(
        QWidget* pParent,
        const std::function<void()>& fnClearComputation,
        const std::function<void()>& fnClearEnergy
    );

    QWidget* pComputationPage() const noexcept;
    QWidget* pEnergyPage() const noexcept;
    void setRecords(
        const std::vector<tesla::metrics::AuthenticationMetricRecord>& vecComputationRecords,
        const std::vector<tesla::metrics::AuthenticationMetricRecord>& vecEnergyRecords
    );

private:
    void updateChart(
        const std::vector<tesla::metrics::AuthenticationMetricRecord>& vecRecords,
        bool bEnergy
    );
    static void configureSeries(QLineSeries* pSeries, const QString& strName);
    static void updateAxes(
        QValueAxis* pXAxis,
        QValueAxis* pYAxis,
        qreal dMaximumX,
        qreal dMaximumY
    );
    QWidget*     m_pComputationPage;
    QWidget*     m_pEnergyPage;
    QLabel*      m_pComputationSummary;
    QLabel*      m_pHardwareSummary;
    QLabel*      m_pEnergySummary;
    QLineSeries* m_pNativeVerifySeries;
    QLineSeries* m_pFastVerifySeries;
    QLineSeries* m_pNativeEnergySeries;
    QLineSeries* m_pFastEnergySeries;
    QValueAxis*  m_pComputationXAxis;
    QValueAxis*  m_pComputationYAxis;
    QValueAxis*  m_pEnergyXAxis;
    QValueAxis*  m_pEnergyYAxis;
};
