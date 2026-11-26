#pragma once

#include "protocol/ProtocolTypes.h"

#include <QByteArray>

namespace tesla::gui
{
/// 只折叠已知有效长度之后的全零区域；非零填充区必须完整展示。
inline qsizetype nMessageDisplayByteCount(
    const QByteArray& arrMessage,
    std::uint32_t u32MessageByteCount
)
{
    if (arrMessage.size() != protocol::BINARY_BLOCK_SIZE
        || u32MessageByteCount == 0
        || u32MessageByteCount > protocol::BINARY_BLOCK_SIZE)
    {
        return arrMessage.size();
    }

    for (qsizetype nIndex = u32MessageByteCount; nIndex < arrMessage.size(); ++nIndex)
    {
        if (arrMessage[nIndex] != '\0')
        {
            return arrMessage.size();
        }
    }

    return u32MessageByteCount;
}
}
