#include "protocol/ProtocolTypes.h"

#include <utility>

namespace tesla::protocol
{
std::uint32_t u32FileMessageByteCount(
    std::uint64_t u64OriginalByteCount,
    std::uint32_t u32PacketIndex
) noexcept
{
    if (u32PacketIndex == 0)
    {
        return BINARY_BLOCK_SIZE;
    }

    const std::uint64_t u64Offset =
        static_cast<std::uint64_t>(u32PacketIndex - 1U) * BINARY_BLOCK_SIZE;
    if (u64Offset >= u64OriginalByteCount)
    {
        return BINARY_BLOCK_SIZE;
    }

    const std::uint64_t u64Remaining = u64OriginalByteCount - u64Offset;
    return u64Remaining < BINARY_BLOCK_SIZE
        ? static_cast<std::uint32_t>(u64Remaining) : BINARY_BLOCK_SIZE;
}

// 错误对象只保留分类和可读说明，避免把不可信或敏感原始载荷带入日志。
ProtocolDecodeError::ProtocolDecodeError(
    ProtocolDecodeErrorCode errCode,
    std::string strMessage
)
    : m_errCode(errCode),
      m_strMessage(std::move(strMessage))
{
}

ProtocolDecodeErrorCode ProtocolDecodeError::errCode() const noexcept
{
    return m_errCode;
}

const std::string& ProtocolDecodeError::strMessage() const noexcept
{
    return m_strMessage;
}
}
