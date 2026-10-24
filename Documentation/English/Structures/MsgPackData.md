# MsgPackData

## Overview
Obscure structure that 

## Structure

```purebasic
Structure MsgPackData
	; Offset used when reading or writing.
	BufferOffset.i
	
	; Used in place of `MemorySize()` to reduce syscalls.
	BufferSize.i
	
	; Temp mechanism for buffer growth.
	BufferGrowthIncrements.i

	; IteratorSizeLeft, or snoething like this.
	
	; LastError code
	LastError.MsgPack_ErrorCode
	
	; TODO
	DataFlags.MsgPack_DataFlag
	
	; Pointer to a data buffer.
	; Can be freed by the caller or this module.
	*Buffer
EndStructure
```

## Fields

<table>
    <thead>
        <th>Name</th>
        <th>Type</th>
        <th>Details</th>
    </thead>
    <tbody>
        <tr>
            <td><code>BufferOffset</code></td>
            <td><code>.i</code></td>
            <td>Internal offset into **Buffer*</td>
        </tr>
        <tr>
            <td><code>BufferSize</code></td>
            <td><code>.i</code></td>
            <td>...</td>
        </tr>
        <tr>
            <td><code>BufferGrowthIncrements</code></td>
            <td><code>.i</code></td>
            <td>...</td>
        </tr>
        <tr>
            <td><code>LastError</code></td>
            <td><code>.MsgPack_ErrorCode</code></td>
            <td>...</td>
        </tr>
        <tr>
            <td><code>DataFlags</code></td>
            <td><code>.MsgPack_DataFlag</code></td>
            <td>...</td>
        </tr>
        <tr>
            <td><code>Buffer</code></td>
            <td><i>Pointer</i></td>
            <td>...</td>
        </tr>
    </tbody>
</table>

