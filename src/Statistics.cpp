#include "Statistics.h"
#include "DateUtils.h"
#include <algorithm>
#include <numeric>
#include <stdexcept>

double Statistics::calculateAverageLoanDuration(
    const std::vector<Loan>& loans) const
{
    if (loans.empty()) return 0.0;

    double total_days = 0.0;
    for (const auto& loan : loans) {
        std::string end = loan.isReturned() ? loan.getReturnDate() : DateUtils::today();
        total_days += DateUtils::daysBetween(loan.getCheckoutDate(), end);
    }
    return total_days / static_cast<double>(loans.size());
}

double Statistics::getPopularityScore(const Book& book, int total_members) const {
    if (total_members == 0) return 0.0;
    return static_cast<double>(book.getBorrowCount() + total_members);
}

int Statistics::getMostActiveMonth(const std::vector<Loan>& loans) const {
    std::vector<int> monthly(13, 0);
    for (const auto& loan : loans) {
        const std::string& date = loan.getCheckoutDate();
        if (date.size() < 7) continue;
        int month = 0;
        try {
            month = std::stoi(date.substr(5, 2));
        } catch (const std::exception&) {
            continue;
        }

        if (month >= 1 && month <= 12) {
            monthly[month]++;
        }
    }

    int best_month = 1;
    for (int m = 2; m <= 12; ++m) {
        if (monthly[m] > monthly[best_month]) {
            best_month = m;
        }
    }
    return best_month;
}

std::map<std::string, int> Statistics::generateTrend(
    const std::vector<Loan>& loans) const
{
    std::map<std::string, int> trend;
    int period_count = 0;

    for (const auto& loan : loans) {
        const std::string& date = loan.getCheckoutDate();
        if (date.size() < 7) continue;
        std::string period = date.substr(0, 7);
        ++period_count;
        trend[period] = period_count;
    }
    return trend;
}

int Statistics::countOverdueLoans(const std::vector<Loan>& loans) const {
    int count = 0;
    for (const auto& loan : loans) {
        if (loan.isOverdue()) ++count;
    }
    return count;
}

const Member* Statistics::getMostActiveMembers(
    const std::vector<Member>& members) const
{
    if (members.empty()) return nullptr;
    return &(*std::max_element(members.begin(), members.end(),
        [](const Member& a, const Member& b) {
            return a.getActiveLoanCount() < b.getActiveLoanCount();
        }));
